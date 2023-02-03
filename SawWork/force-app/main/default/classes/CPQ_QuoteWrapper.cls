public abstract class CPQ_QuoteWrapper {

    public Id quoteId { get; set; }
    public String name { get; set; }
    public List<CPQ_QuoteLineWrapper> productLines { get; set; }
    public List<CPQ_QuoteLineWrapper> integrationLines { get; set; }
    public Decimal monthlyFees { get; set; }
    public Decimal oneTimeFees { get; set; }
    public Boolean intProdExists {get; set;}
    public Boolean stdSupportExists {get; set;}
    public Boolean excludeAdjustableFees {get; set;}
    public String currencyCode {get;set;}
    public String currencySymbol {get;set;}
    public Decimal yearlyFees {get;set;}
    public Decimal projectedMinOrderValue {get;set;}


    //createing the extension of quote line class as Abstract classes cannot be constructed
    public CPQ_QuoteWrapper() {

        System.debug(System.LoggingLevel.INFO, '---Inside the QuoteWrapper base class constructor---');

        // default Initialization 

        this.quoteId = null;
        this.name = '';
        this.monthlyFees = 0.0;
        this.oneTimeFees = 0.0;
        this.intProdExists = false;
        this.stdSupportExists = false;
        this.excludeAdjustableFees = false;
        this.currencyCode = 'USD';
        this.currencySymbol = '';
        this.yearlyFees = 0.0;
        this.projectedMinOrderValue = 0.0;
        

    }
}