const {setGlobalOptions} = require("firebase-functions");

setGlobalOptions({
  maxInstances: 10,
});

const orderNotifications = require("./notifications/orderNotifications");

exports.onOrderCreated = orderNotifications.onOrderCreated;
