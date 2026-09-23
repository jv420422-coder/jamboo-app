const {onDocumentUpdated} =
    require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {db} = require("../utils/firebase");

const updateSoldQuantity = onDocumentUpdated(
    "orders/{orderId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      const beforeStatus =
          String(before.orderStatus || "").toLowerCase();

      const afterStatus =
          String(after.orderStatus || "").toLowerCase();

      if (
        beforeStatus === "delivered" ||
        afterStatus !== "delivered"
      ) {
        return;
      }

      if (after.soldQuantityProcessed === true) {
        return;
      }

      const items = Array.isArray(after.items) ?
          after.items :
          [];

      if (items.length === 0) {
        return;
      }

      await db.runTransaction(async (transaction) => {
        const orderRef =
            db.collection("orders").doc(event.params.orderId);

        const orderSnapshot =
            await transaction.get(orderRef);

        const orderData =
            orderSnapshot.data() || {};

        if (orderData.soldQuantityProcessed === true) {
          return;
        }

        transaction.update(orderRef, {
          soldQuantityProcessed: true,
        });

        for (const item of items) {
          const itemId =
              String(item.itemId || item.id || "");

          const quantity =
              Number(item.quantity || 0);

          if (!itemId || quantity <= 0) {
            continue;
          }

          const menuItemRef =
              db.collection("menu_items").doc(itemId);

          transaction.set(
              menuItemRef,
              {
                soldQuantity:
                    admin.firestore.FieldValue.increment(
                        quantity,
                    ),
              },
              {merge: true},
          );
        }
      });
    },
);

module.exports = {
  updateSoldQuantity,
};
