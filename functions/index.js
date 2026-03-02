const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Trigger: /chats/{chatId}/messages/{messageId} → onCreate
 *
 * - senderType === "admin" → notify the user  (tokens in /chats/{chatId}/fcmTokens)
 * - senderType === "user"  → notify all admins (tokens in /admins/{adminId}/fcmTokens)
 */
exports.onNewChatMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const { chatId } = context.params;
    const messageData = snap.data() || {};

    const senderRaw =
      messageData.senderType ??
      messageData.sender ??
      messageData.lastMessageBy ??
      messageData.from ??
      "";

    const sender = String(senderRaw).toLowerCase().trim();

    const type = String(messageData.type ?? "text").toLowerCase();
    const text =
      type === "image"
        ? "📷 Photo"
        : messageData.text ?? messageData.message ?? "New message";

    console.log("New chat message", { chatId, sender, type });

    try {
      if (sender === "admin") {
        await sendToChatUser(chatId, text);
      } else if (sender === "user") {
        const chatDoc = await admin
          .firestore()
          .collection("chats")
          .doc(chatId)
          .get();
        const userName = chatDoc.exists
          ? chatDoc.data().userName || "User"
          : "User";
        await sendToAdmins(chatId, userName, text);
      } else {
        console.log("Skipped push: sender not recognized", { senderRaw });
      }
    } catch (error) {
      console.error("Push notification error:", error);
    }
  });

/**
 * Send push to the chat user.
 * Tokens stored in: /chats/{chatId}/fcmTokens/{tokenDoc}
 */
async function sendToChatUser(chatId, messageText) {
  const tokensSnap = await admin
    .firestore()
    .collection("chats")
    .doc(chatId)
    .collection("fcmTokens")
    .get();

  if (tokensSnap.empty) {
    console.log(`No user tokens in chats/${chatId}/fcmTokens`);
    return;
  }

  const tokens = tokensSnap.docs
    .map((doc) => doc.data().token || doc.id)
    .filter(Boolean);

  if (tokens.length === 0) {
    console.log(`User token docs exist but empty values for chat ${chatId}`);
    return;
  }

  console.log(`Sending to user tokens: ${tokens.length} (chatId=${chatId})`);

  const payload = {
    notification: {
      title: "New message from support",
      body: messageText,
    },
    data: {
      type: "chat",
      chatId: chatId,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  const resp = await admin
    .messaging()
    .sendEachForMulticast({ tokens, ...payload });
  await cleanupTokens(tokensSnap.docs, resp);
}

/**
 * Send push to ALL admins.
 * Tokens stored in: /admins/{adminId}/fcmTokens/{tokenDoc}
 */
async function sendToAdmins(chatId, userName, messageText) {
  const allTokens = [];
  const allDocs = [];

  const adminsSnap = await admin.firestore().collection("admins").get();

  if (!adminsSnap.empty) {
    for (const adminDoc of adminsSnap.docs) {
      const tokenSnap = await adminDoc.ref.collection("fcmTokens").get();
      for (const tokenDoc of tokenSnap.docs) {
        const token = tokenDoc.data().token || tokenDoc.id;
        if (token) {
          allTokens.push(token);
          allDocs.push(tokenDoc);
        }
      }
    }
  } else {
    console.log(
      "No admin docs found under /admins. Falling back to collectionGroup(fcmTokens)."
    );

    const tokenSnap = await admin.firestore().collectionGroup("fcmTokens").get();
    for (const tokenDoc of tokenSnap.docs) {
      const parentDoc = tokenDoc.ref.parent.parent;
      const parentCollection = parentDoc?.parent?.id;

      if (parentCollection !== "admins") continue;

      const token = tokenDoc.data().token || tokenDoc.id;
      if (token) {
        allTokens.push(token);
        allDocs.push(tokenDoc);
      }
    }
  }

  if (allTokens.length === 0) {
    console.log(
      "No admin FCM tokens found under /admins/*/fcmTokens after scanning available admin records."
    );
    return;
  }

  console.log(`Sending to admin tokens: ${allTokens.length}`);

  const payload = {
    notification: {
      title: `Message from ${userName}`,
      body: messageText,
    },
    data: {
      type: "chat",
      chatId: chatId,
      userName: userName,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  const resp = await admin.messaging().sendEachForMulticast({
    tokens: allTokens,
    ...payload,
  });

  await cleanupTokens(allDocs, resp);
}

/**
 * Remove invalid/expired tokens from Firestore.
 */
async function cleanupTokens(tokenDocs, response) {
  if (!response || !response.responses) return;

  const tokensToDelete = [];
  response.responses.forEach((result, index) => {
    if (result.error) {
      const code = result.error.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        tokensToDelete.push(tokenDocs[index].ref.delete());
      }
    }
  });

  if (tokensToDelete.length > 0) {
    await Promise.all(tokensToDelete);
    console.log(`Cleaned up ${tokensToDelete.length} invalid tokens`);
  }
}
