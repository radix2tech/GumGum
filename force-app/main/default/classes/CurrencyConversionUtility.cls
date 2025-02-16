public class CurrencyConversionUtility {

    private static Map<String, List<DatedConversionRate>> exchangeRateCache = new Map<String, List<DatedConversionRate>>();

    public static Decimal getExchangeRate(String currencyIsoCode, Date targetDate) {

        // Ensure all exchange rates are loaded into the cache
        if (exchangeRateCache.isEmpty()) {
            loadAllExchangeRates();
        }

        // Retrieve rates for the currency from the cache
        List<DatedConversionRate> rates = exchangeRateCache.get(currencyIsoCode);
        if (rates != null) {
            for (DatedConversionRate rate : rates) {
                if (rate.StartDate <= targetDate && rate.NextStartDate > targetDate) {
                    return rate.ConversionRate;
                }
            }
        }

        return 1;
    }

    private static void loadAllExchangeRates() {
        // Query all exchange rates for all currencies
        List<DatedConversionRate> allRates = [
            SELECT IsoCode, ConversionRate, StartDate, NextStartDate
            FROM DatedConversionRate
        ];

        // Populate the cache with rates grouped by IsoCode
        for (DatedConversionRate rate : allRates) {
            if (!exchangeRateCache.containsKey(rate.IsoCode)) {
                exchangeRateCache.put(rate.IsoCode, new List<DatedConversionRate>());
            }
            exchangeRateCache.get(rate.IsoCode).add(rate);
        }
    }
}