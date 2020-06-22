(ns dog-bot.scraper
  (:require [etaoin.api :as api]
            [chime.core :as chime]
            [clojure.edn :as edn]
            [clojure.string :as string]

            [clj-http.client :as http])
  (:import  [java.time Instant Duration]))

(def db (atom #{}))
(def env (edn/read-string (slurp "env.edn")))

(defn fetch-dog-names []
  (api/with-firefox {:headless true} driver
    (api/go driver "https://indyhumane.org/adoptable-dogs/")
    (api/wait-exists driver {:id "mbc-petpoint-results-stage2"})
    (doall
      (map #(api/get-element-text-el driver %)
           (api/query-all driver {:class "mbcpp_result_name"})))))


(defn message [dog-names]
  (str "\n" "The list of dogs changed!" "\n\n"
    "https://indyhumane.org/adoptable-dogs/" "\n\n"
    "Here's the current list of dog names:" "\n\n" (string/join ", " (sort dog-names))))

(defn trigger-sms! [dog-names]
  (http/post
   (get-in env [:twilio :send-endpoint])
   {:basic-auth [(get-in env [:twilio :account-id]) (get-in env [:twilio :auth-token])]
    :form-params  {"To" (:sms-to env), "From" (:sms-from env), "Body" (message dog-names) }}))

(defn check-for-new-dogs []
  (let [dog-names (into #{} (fetch-dog-names))]
    (println "Found dogs: " dog-names)
    (when (not= dog-names @db)
      (println "Dogs list has changed!")
      (reset! db dog-names)
      (trigger-sms! dog-names))))

(defn start-schedule []
  (-> (chime/periodic-seq (Instant/now) (Duration/ofMinutes (:interval-minutes env)))
      (chime/chime-at (fn [time]
                        (println "Checking for dogs at " time)
                        (check-for-new-dogs)))))

(defn -main []
  (start-schedule))

(comment
  (trigger-sms! "neat")
  (check-for-new-dogs)
  (start-schedule)

  )
