global class SF1_CurrencySelectionController {
    @AuraEnabled
	public static List<String> getOpptyCurrencyOptions() {
        return GsmUtilClass.getCurrencyIsoCodes();
	}
}