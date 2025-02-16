@IsTest
public class CurrencyConversionUtilityTest {
	@IsTest
    static void getExchangeRate() {
		CurrencyConversionUtility.getExchangeRate('USD',Date.Today());
    }
}