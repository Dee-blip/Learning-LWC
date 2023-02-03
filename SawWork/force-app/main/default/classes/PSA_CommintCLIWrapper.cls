/*
Createdby 	: Sujay 
Purpose 	: This wrapper class is used in PSA_OverageController for creating instances of Contract Details with executing additonal SOQL
Date 		: 18 March 2020
*/
public class PSA_CommintCLIWrapper {
	public Id cmtId;
    public Date EffectiveEndDate;
    public Date EffectiveStartDate;
    public String UnitOfMeasure;
    public Decimal UnitsLow;
    public String BillingDuration;
    
    public PSA_CommintCLIWrapper(Id cmtId, Date EffectiveEndDate, Date EffectiveStartDate,String UnitOfMeasure, Decimal UnitsLow, String BillingDuration){
        this.cmtId 				= cmtId;
		this.EffectiveEndDate 	= EffectiveEndDate;
		this.EffectiveStartDate = EffectiveStartDate;
		this.UnitOfMeasure 		= UnitOfMeasure;
		this.UnitsLow 			= UnitsLow;
		this.BillingDuration 	= BillingDuration;
    }
}