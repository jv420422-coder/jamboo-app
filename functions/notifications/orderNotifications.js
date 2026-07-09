const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const {db} = require("../utils/firebase");

const onOrderCreated = onDocumentCreated(
    "orders/{orderId}",
    async (event) => {
      try {
        const order = event.data.data();

        const orderNumber =
        order.orderNumber || event.params.orderId;

        logger.info(`New order received: ${orderNumber}`);

        await db.collection("notifications").add({
          userId: order.userId,
          title: "Order Placed 🎉",
          body:
          "Your order has been placed successfully. " +
          "The restaurant will confirm it soon.",
          type: "order_placed",
          orderId: event.params.orderId,
          isRead: false,
          createdAt: new Date(),
        });

        logger.info("Notification document created.");
      } catch (error) {
        logger.error(error);
      }
    },
);

module.exports = {
  onOrderCreated,
};
