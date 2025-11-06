const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "asia-southeast1" });

exports.notifyLowStockV2 = onDocumentUpdated("spare_part/{productId}", async (event) => {
  const before = event.data?.before?.data() || {};
  const after  = event.data?.after?.data();
  if (!after) return;

  const productId   = event.params.productId;
  const productName = after.name ?? productId;
  const imageUrl    = after.imageUrl ?? "";

  const thresholdRaw = after.stockThreshold;
  const threshold    = Number(thresholdRaw);

  if (!Number.isFinite(threshold)) {
    console.log("Skip: invalid stockThreshold on doc", { thresholdRaw });
    return;
  }

  const beforeStock = Number(before.stock);
  const afterStock  = Number(after.stock);

  const crossedDown = Number.isFinite(beforeStock)
    ? (beforeStock >= threshold && afterStock < threshold)
    : (afterStock < threshold);

  if (!Number.isFinite(afterStock) || !crossedDown) {
    console.log("Skip: no crossing", { beforeStock, afterStock, threshold });
    return;
  }

  const db = admin.firestore();
  const notifId  = `${productId}_${event.id}`;
  const notifRef = db.collection("notification").doc(notifId);
  await notifRef.set({
    notifId,
    title: "Low Stock Alert !!!",
    body: `Stock for ${productName} has dropped below ${threshold} units. Please restock as soon as possible to avoid any potential disruptions.).`,
    productId,
    productName,
    stock: afterStock,
    stockThreshold: threshold,
    imageUrl,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  try {
    await admin.messaging().send({
      topic: "lowStockTopic",
      notification: {
        title: "Low Stock Alert !!!",
        body: `Stock for ${productName} has dropped below ${threshold} units. Please restock as soon as possible to avoid any potential disruptions.).`,
      },
      android: {
        notification: {
          channelId: "default_channel",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      data: {
        notifId,
        productId,
        productName,
        stock: String(afterStock),
        stockThreshold: String(threshold),
        imageUrl,
        route: "spare_part_detail",
      },
    });
    console.log("FCM sent");
  } catch (err) {
    console.error("FCM failed to send:", err);
  }
});
