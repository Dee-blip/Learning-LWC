public abstract class CPQ_QuoteLineWrapper {

    public String Id {get; set;}
    public String name {get; set;}
    public String quantity {get; set;}
    // public String netPrice {get; set;}
    public Decimal netPrice {get;set;}
    public Decimal netTotal {get; set;}
    public String uom {get; set;}
    public String billingFrequency {get; set;}
    public String prodMrktCode {get; set;}
    public String billingModel {get; set;}
    public List<CPQ_QuoteLineWrapper> periodCommitLines {get; set;}
    public String timePeriod {get; set;}
    public Decimal commitType {get; set;}
    public Decimal overageRate {get; set;}
    public String rateSuffix {get; set;}
    public String productCode {get; set;}
    public Boolean isMain {get; set;}
    public Boolean isFLProd {get; set;}
    public List<CPQ_QuoteLineWrapper> quoteLines {get; set;}
    public String prodDesc {get; set;}
    public Boolean usage {get; set;}
    public Decimal oneTimeFee { get; set; }
    public Decimal netQuantity {get; set; }

    public CPQ_QuoteLineWrapper() {

        System.debug(System.LoggingLevel.INFO, '---Inside the QuoteLineWrapper base class constructor---');

        //default initialization 

        this.Id = null;
        this.name = '';
        this.quantity = '';
        this.netPrice = 0.0;
        this.netTotal = 0.0;
        this.uom = '';
        this.billingFrequency = '';
        this.prodMrktCode = '';
        this.billingModel = '';
        this.periodCommitLines = new List<CPQ_QuoteLineWrapper>();
        this.timePeriod = '';
        this.commitType = 0.0;
        this.overageRate = 0.0;
        this.rateSuffix = ''; 
        this.productCode = '';
        this.isFLProd = false;
        this.isMain = false;
        this.quoteLines = new List<CPQ_QuoteLineWrapper>();
        this.prodDesc = '';
        this.usage = false;
        this.oneTimeFee = 0.0;
        this.netQuantity = 0;

    }
}