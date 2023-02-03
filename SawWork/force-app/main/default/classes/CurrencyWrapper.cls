public without sharing class CurrencyWrapper {
    SObject sobj;
    public CurrencyWrapper(SObject sobj) {
        this.sobj = sobj;       
    }
   
    public Integer getDecimalPlaces() {
        return (Integer) sobj.get('DecimalPlaces');
    }
   
    public Decimal getConversionRate() {
        return (Decimal) sobj.get('ConversionRate');
    }
    
    public boolean isCorporateCurrency() {
        return (boolean) sobj.get('IsCorporate');
    }

    public String getIsoCode() {
        return (String) sobj.get('IsoCode');
    }
    
}