const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} =
    require("firebase-functions/v2/https");
const {defineSecret} =
    require("firebase-functions/params");
const googleMapsApiKey =
    defineSecret("GOOGLE_MAPS_API_KEY");
const admin = require("firebase-admin");
const OpenAI = require("openai");

setGlobalOptions({
  maxInstances: 10,
});

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const orderNotifications =
    require("./notifications/orderNotifications");

const openaiApiKey =
    defineSecret("OPENAI_API_KEY");

exports.onOrderCreated =
    orderNotifications.onOrderCreated;

const soldQuantity =
    require("./notifications/soldQuantity");

exports.updateSoldQuantity =
    soldQuantity.updateSoldQuantity;

// ============================================================
// JAMBOO AI
// ============================================================

exports.jambooAI = onCall(
    {
      secrets: [openaiApiKey],
      region: "asia-south1",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Please login to use Jamboo AI.",
        );
      }

      const message = request.data?.message;

      if (
        typeof message !== "string" ||
        message.trim().length === 0
      ) {
        throw new HttpsError(
            "invalid-argument",
            "Message is required.",
        );
      }

      try {
        const restaurantsSnapshot = await db
            .collection("restaurant_registrations")
            .where(
                "verificationStatus",
                "==",
                "approved",
            )
            .where(
                "isActive",
                "==",
                true,
            )
            .where(
                "isOpen",
                "==",
                true,
            )
            .get();

        const restaurants = {};

        restaurantsSnapshot.docs.forEach((doc) => {
          const data = doc.data();

          const restaurantId =
              (
                data.restaurantId ||
                doc.id
              ).toString();

          restaurants[restaurantId] = {
            id: restaurantId,
            name:
                data.restaurantName ||
                "Restaurant",
            rating:
                Number(data.averageRating || 0),
            totalRatings:
                Number(data.totalRatings || 0),
          };
        });

        if (Object.keys(restaurants).length === 0) {
          return {
            success: true,
            reply:
                "😔 Abhi Jamboo par koi open restaurant " +
                "available nahi hai.",
            recommendations: [],
          };
        }

        const menuSnapshot = await db
            .collection("menu_items")
            .where(
                "isActive",
                "==",
                true,
            )
            .where(
                "isAvailable",
                "==",
                true,
            )
            .get();

        const menuItems = [];

        menuSnapshot.docs.forEach((doc) => {
          const data = doc.data();

          const restaurantId =
              (data.restaurantId || "").toString();

          if (!restaurants[restaurantId]) {
            return;
          }

          const price =
              Number(data.price || 0);

          if (price <= 0) {
            return;
          }

          menuItems.push({
            id: doc.id,
            name:
                data.name || "Food item",
            description:
                data.description || "",
            category:
                data.category || "",
            price: price,
            rating:
                Number(data.rating || 0),
            totalRatings:
                Number(data.totalRatings || 0),
            isBestseller:
                data.isBestseller === true,
            isRecommended:
                data.isRecommended === true,
            restaurantId: restaurantId,
            restaurantName:
                restaurants[restaurantId].name,
            restaurantRating:
                restaurants[restaurantId].rating,
            restaurantTotalRatings:
                restaurants[restaurantId]
                    .totalRatings,
            imageUrl:
                data.imageUrl || "",
            emoji:
                data.emoji || "🍽️",
            preparationTime:
                Number(data.preparationTime || 20),
            soldQuantity:
                Number(data.soldQuantity || 0),
          });
        });

        if (menuItems.length === 0) {
          return {
            success: true,
            reply:
                "😔 Abhi koi available food item " +
                "nahi mila.",
            recommendations: [],
          };
        }

        const userMessage =
            message.trim().toLowerCase();

        let candidates = [...menuItems];

        const budgetMatch =
            userMessage.match(
                // eslint-disable-next-line max-len
                /(?:under|below|within|less than|upto|up to|₹|rs\.?|rupees?)\s*(\d+)/i,
            );

        if (
          userMessage.includes("under 200") ||
          userMessage.includes("₹200") ||
          userMessage.includes("200 ke andar") ||
          userMessage.includes("200 ke under")
        ) {
          candidates = candidates.filter(
              (item) => item.price <= 200,
          );
        } else if (budgetMatch) {
          const budget =
              Number(budgetMatch[1]);

          if (budget > 0) {
            candidates = candidates.filter(
                (item) => item.price <= budget,
            );
          }
        }

        const requestedCategories = [
          "pizza",
          "burger",
          "momos",
          "momo",
          "biryani",
          "noodles",
          "paneer",
          "chicken",
          "dessert",
          "pasta",
          "sandwich",
          "roll",
          "wrap",
        ];

        for (const category
          of requestedCategories) {
          if (userMessage.includes(category)) {
            const categoryItems =
                candidates.filter((item) =>
                  item.category
                      .toLowerCase()
                      .includes(category) ||
                  item.name
                      .toLowerCase()
                      .includes(category),
                );

            if (categoryItems.length > 0) {
              candidates = categoryItems;
            }

            break;
          }
        }

        candidates.sort((a, b) => {
          const salesA =
              a.soldQuantity || 0;

          const salesB =
              b.soldQuantity || 0;

          const ratingA =
              a.rating > 0 ?
                  a.rating :
                  a.restaurantRating;

          const ratingB =
              b.rating > 0 ?
                  b.rating :
                  b.restaurantRating;

          const scoreA =
              salesA * 3 +
              ratingA * 20 +
              Math.min(
                  a.totalRatings,
                  100,
              ) +
              (a.isBestseller ? 40 : 0) +
              (a.isRecommended ? 30 : 0);

          const scoreB =
              salesB * 3 +
              ratingB * 20 +
              Math.min(
                  b.totalRatings,
                  100,
              ) +
              (b.isBestseller ? 40 : 0) +
              (b.isRecommended ? 30 : 0);

          return scoreB - scoreA;
        });

        const recommendations =
            candidates.slice(0, 3);

        if (recommendations.length === 0) {
          return {
            success: true,
            reply:
                "😔 Is budget ya preference mein " +
                "abhi koi available item nahi mila. " +
                "Thoda budget increase karke try karein.",
            recommendations: [],
          };
        }

        const candidateText =
            recommendations.map((item) => {
              const sold =
                  item.soldQuantity || 0;

              return [
                `Item ID: ${item.id}`,
                `Food: ${item.name}`,
                `Category: ${item.category}`,
                `Description: ${item.description}`,
                `Price: ₹${item.price}`,
                `Item Rating: ${item.rating}`,
                `Item Ratings Count: ` +
                    `${item.totalRatings}`,
                `Sold Quantity: ${sold}`,
                `Bestseller: ${item.isBestseller}`,
                `Recommended: ${item.isRecommended}`,
                `Restaurant: ${item.restaurantName}`,
                `Restaurant Rating: ` +
                    `${item.restaurantRating}`,
                `Restaurant Ratings Count: ` +
                    `${item.restaurantTotalRatings}`,
              ].join("\n");
            }).join("\n\n");

        const openai = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        const response =
            await openai.responses.create({
              model: "gpt-5.6-luna",
              instructions:
                  "You are Jamboo AI, the food " +
                  "recommendation assistant inside " +
                  "the Jamboo food delivery app.\n\n" +
                  "IMPORTANT RULES:\n" +
                  "1. Recommend ONLY items from the " +
                  "provided list.\n" +
                  "2. Never invent any item, restaurant, " +
                  "price, rating or availability.\n" +
                  "3. Respect the user's budget.\n" +
                  "4. Prefer stronger sales, ratings, " +
                  "ratings count, Bestseller and " +
                  "Recommended status.\n" +
                  "5. Mention the actual restaurant " +
                  "and price.\n" +
                  "6. Reply in natural Hinglish when " +
                  "the user uses Hindi or Hinglish.\n" +
                  "7. Keep the response concise.\n" +
                  "8. The provided items are the exact " +
                  "items shown as clickable cards below " +
                  "your answer.\n" +
                  "9. Do not ask the user whether you " +
                  "should add an item to the cart.\n" +
                  "10. Tell the user they can tap the " +
                  "plus button on a recommended item " +
                  "to add it to the cart.",
              input:
                  "USER REQUEST:\n" +
                  message.trim() +
                  "\n\nAVAILABLE JAMBOO FOOD ITEMS:\n" +
                  candidateText,
            });

        return {
          success: true,
          reply:
              (response.output_text ||
                "Sorry, mujhe abhi recommendation " +
                "nahi mil paayi.")
                  .replace(/\*\*/g, ""),
          recommendations:
              recommendations.map((item) => ({
                id: item.id,
                name: item.name,
                description: item.description,
                price: item.price,
                rating: item.rating,
                totalRatings:
                    item.totalRatings,
                restaurantId:
                    item.restaurantId,
                restaurantName:
                    item.restaurantName,
                imageUrl:
                    item.imageUrl,
                emoji:
                    item.emoji,
                preparationTime:
                    item.preparationTime,
                soldQuantity:
                    item.soldQuantity || 0,
              })),
        };
      } catch (error) {
        console.error(
            "Jamboo AI error:",
            error,
        );

        throw new HttpsError(
            "internal",
            "Jamboo AI is temporarily unavailable. " +
            "Please try again.",
        );
      }
    },
);

// ============================================================
// DELETE CUSTOMER ACCOUNT
// ============================================================

exports.deleteCustomerAccount = onCall(
    {
      region: "asia-south1",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Please login to delete your account.",
        );
      }

      const uid = request.auth.uid;

      try {
        // --------------------------------------------------------
        // 1. Get customer ratings before deleting them
        // --------------------------------------------------------

        const ratingsSnapshot = await db
            .collection("ratings")
            .where("customerId", "==", uid)
            .get();

        const affectedRestaurantIds = new Set();

        for (const doc of ratingsSnapshot.docs) {
          const data = doc.data();

          if (data.restaurantId) {
            affectedRestaurantIds.add(
                data.restaurantId.toString(),
            );
          }
        }

        // --------------------------------------------------------
        // 2. Delete customer ratings
        // --------------------------------------------------------

        const ratingsBatch = db.batch();

        for (const doc of ratingsSnapshot.docs) {
          ratingsBatch.delete(doc.ref);
        }

        if (!ratingsSnapshot.empty) {
          await ratingsBatch.commit();
        }

        // --------------------------------------------------------
        // 3. Delete delivery partner ratings
        // --------------------------------------------------------

        const deliveryRatingsSnapshot = await db
            .collection("delivery_partner_ratings")
            .where("customerId", "==", uid)
            .get();

        const deliveryRatingsBatch = db.batch();

        for (const doc of deliveryRatingsSnapshot.docs) {
          deliveryRatingsBatch.delete(doc.ref);
        }

        if (!deliveryRatingsSnapshot.empty) {
          await deliveryRatingsBatch.commit();
        }

        // --------------------------------------------------------
        // 4. Delete customer notifications
        // --------------------------------------------------------

        const notificationsSnapshot = await db
            .collection("notifications")
            .where("userId", "==", uid)
            .get();

        const notificationsBatch = db.batch();

        for (const doc of notificationsSnapshot.docs) {
          notificationsBatch.delete(doc.ref);
        }

        if (!notificationsSnapshot.empty) {
          await notificationsBatch.commit();
        }

        // --------------------------------------------------------
        // 5. Delete saved addresses
        // --------------------------------------------------------

        const addressesRef = db
            .collection("users")
            .doc(uid)
            .collection("addresses");

        await db.recursiveDelete(addressesRef);

        // --------------------------------------------------------
        // 6. Delete cart
        // --------------------------------------------------------

        const cartRef = db
            .collection("users")
            .doc(uid)
            .collection("cart");

        await db.recursiveDelete(cartRef);

        // --------------------------------------------------------
        // 7. Delete customer profile
        // --------------------------------------------------------

        const userRef = db
            .collection("users")
            .doc(uid);

        await userRef.delete();

        // --------------------------------------------------------
        // 8. Recalculate affected restaurant ratings
        // --------------------------------------------------------

        for (const restaurantId of affectedRestaurantIds) {
          const remainingRatingsSnapshot = await db
              .collection("ratings")
              .where(
                  "restaurantId",
                  "==",
                  restaurantId,
              )
              .get();

          let total = 0;
          let validRatings = 0;

          for (
            const doc
            of remainingRatingsSnapshot.docs
          ) {
            const data = doc.data();
            const value = data.rating;

            if (typeof value === "number") {
              total += value;
              validRatings++;
            }
          }

          const average =
              validRatings === 0 ?
                  0 :
                  total / validRatings;

          await db
              .collection("restaurant_registrations")
              .doc(restaurantId)
              .set(
                  {
                    averageRating: average,
                    totalRatings: validRatings,
                  },
                  {
                    merge: true,
                  },
              );
        }

        // --------------------------------------------------------
        // 9. Delete Firebase Authentication account
        // --------------------------------------------------------

        await admin.auth().deleteUser(uid);

        return {
          success: true,
          message: "Jamboo account deleted successfully.",
        };
      } catch (error) {
        console.error(
            "DELETE CUSTOMER ACCOUNT ERROR:",
            error,
        );

        throw new HttpsError(
            "internal",
            "Unable to delete your account. Please try again.",
        );
      }
    },
);
// ============================================================
// GET ADDRESS FROM CURRENT LOCATION
// ============================================================

exports.getAddressFromCoordinates = onCall(
    {
      secrets: [googleMapsApiKey],
      region: "asia-south1",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Please login to get your address.",
        );
      }

      const latitude = Number(request.data?.latitude);
      const longitude = Number(request.data?.longitude);

      if (
        !Number.isFinite(latitude) ||
        !Number.isFinite(longitude) ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180
      ) {
        throw new HttpsError(
            "invalid-argument",
            "Valid latitude and longitude are required.",
        );
      }

      try {
        const apiKey = googleMapsApiKey.value();

        const url = new URL(
            "https://maps.googleapis.com/maps/api/geocode/json",
        );

        url.searchParams.set(
            "latlng",
            `${latitude},${longitude}`,
        );
        url.searchParams.set("key", apiKey);

        const response = await fetch(url);

        if (!response.ok) {
          throw new Error(
              `Geocoding HTTP error: ${response.status}`,
          );
        }

        const data = await response.json();

        if (data.status !== "OK") {
          console.error(
              "Geocoding API error:",
              data.status,
              data.error_message || "",
          );

          if (data.status === "ZERO_RESULTS") {
            throw new HttpsError(
                "not-found",
                "Address details could not be found.",
            );
          }

          throw new HttpsError(
              "internal",
              "Unable to find your address right now.",
          );
        }

        const result = data.results?.[0];

        if (!result) {
          throw new HttpsError(
              "not-found",
              "Address details could not be found.",
          );
        }

        const components =
            result.address_components || [];

        let streetNumber = "";
        let route = "";
        let subLocality = "";
        let neighborhood = "";
        let locality = "";
        let administrativeArea = "";
        let postalCode = "";

        for (const component of components) {
          const types = component.types || [];
          const longName = component.long_name || "";

          if (types.includes("street_number")) {
            streetNumber = longName;
          } else if (types.includes("route")) {
            route = longName;
          } else if (
            types.includes("sublocality_level_1") ||
            types.includes("sublocality")
          ) {
            subLocality = longName;
          } else if (types.includes("neighborhood")) {
            neighborhood = longName;
          } else if (types.includes("locality")) {
            locality = longName;
          } else if (
            types.includes("administrative_area_level_1")
          ) {
            administrativeArea = longName;
          } else if (types.includes("postal_code")) {
            postalCode = longName;
          }
        }

        const addressParts = [
          streetNumber,
          route,
          subLocality,
        ].filter((part) => part.trim().length > 0);

        return {
          success: true,
          address: addressParts.length > 0 ?
              addressParts.join(", ") :
              (result.formatted_address || ""),
          city: locality,
          state: administrativeArea,
          pincode: postalCode,
          landmark: subLocality || neighborhood,
        };
      } catch (error) {
        if (error instanceof HttpsError) {
          throw error;
        }

        console.error(
            "GET ADDRESS FROM LOCATION ERROR:",
            error,
        );

        throw new HttpsError(
            "internal",
            "Unable to get address. Please try again.",
        );
      }
    },
);
// ============================================================
// GET COORDINATES FROM MANUALLY ENTERED ADDRESS
// ============================================================

exports.getCoordinatesFromAddress = onCall(
    {
      secrets: [googleMapsApiKey],
      region: "asia-south1",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Please login to find your address coordinates.",
        );
      }

      const address =
          typeof request.data?.address === "string" ?
              request.data.address.trim() :
              "";

      const city =
          typeof request.data?.city === "string" ?
              request.data.city.trim() :
              "";

      const state =
          typeof request.data?.state === "string" ?
              request.data.state.trim() :
              "";

      const pincode =
          typeof request.data?.pincode === "string" ?
              request.data.pincode.trim() :
              "";

      if (!address || !city || !state) {
        throw new HttpsError(
            "invalid-argument",
            "Address, city and state are required.",
        );
      }

      try {
        const apiKey = googleMapsApiKey.value();

        const fullAddress = [
          address,
          city,
          state,
          pincode,
          "India",
        ].filter((part) => part.length > 0).join(", ");

        const url = new URL(
            "https://maps.googleapis.com/maps/api/geocode/json",
        );

        url.searchParams.set("address", fullAddress);
        url.searchParams.set("key", apiKey);
        url.searchParams.set("region", "in");

        const response = await fetch(url);

        if (!response.ok) {
          throw new Error(
              `Geocoding HTTP error: ${response.status}`,
          );
        }

        const data = await response.json();

        if (data.status !== "OK" || !data.results?.length) {
          console.error(
              "ADDRESS GEOCODING ERROR:",
              data.status,
              data.error_message || "",
          );

          if (data.status === "ZERO_RESULTS") {
            throw new HttpsError(
                "not-found",
                "Could not find coordinates for this address. " +
                "Please check the address details.",
            );
          }

          throw new HttpsError(
              "internal",
              "Unable to find address coordinates right now.",
          );
        }

        const result = data.results[0];
        const location = result.geometry?.location;

        if (
          !location ||
          !Number.isFinite(location.lat) ||
          !Number.isFinite(location.lng)
        ) {
          throw new HttpsError(
              "not-found",
              "Valid coordinates could not be found.",
          );
        }

        return {
          success: true,
          latitude: location.lat,
          longitude: location.lng,
          formattedAddress:
              result.formatted_address || fullAddress,
          locationType:
              result.geometry?.location_type || "UNKNOWN",
        };
      } catch (error) {
        if (error instanceof HttpsError) {
          throw error;
        }

        console.error(
            "GET COORDINATES FROM ADDRESS ERROR:",
            error,
        );

        throw new HttpsError(
            "internal",
            "Unable to find coordinates. Please try again.",
        );
      }
    },
);
