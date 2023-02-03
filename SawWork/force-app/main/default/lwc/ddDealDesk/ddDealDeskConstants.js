// Fields to query for existing Deal - deal edit mode
export const DEAL_FIELDS = [ 'SC_DD_Deal__c.Account__c', 'SC_DD_Deal__c.AkaTec_Hours_Per_Month__c', 'SC_DD_Deal__c.AkaTec_Delivery_Cost__c', 'SC_DD_Deal__c.AkaTec_Hours__c', 
'SC_DD_Deal__c.AkaTec_per_hour_cost__c', 'SC_DD_Deal__c.Approval_Stage__c', 'SC_DD_Deal__c.Approval_Time_Limit__c', 'SC_DD_Deal__c.Auto_Escalated__c', 
'SC_DD_Deal__c.Average_Monthly_Revenue__c', 'SC_DD_Deal__c.Calculation_Type__c', 'SC_DD_Deal__c.Comments__c', 'SC_DD_Deal__c.Computed_ESR__c', 
'SC_DD_Deal__c.Computed_ESR_Local__c', 'SC_DD_Deal__c.CreatedById', 'SC_DD_Deal__c.CurrencyIsoCode', 'SC_DD_Deal__c.Current_Customer_Role_MRR__c', 
'SC_DD_Deal__c.Current_Profitability_Score__c', 'SC_DD_Deal__c.Deal_Flag__c', 'SC_DD_Deal__c.Name', 'SC_DD_Deal__c.Deal_Zone__c', 'SC_DD_Deal__c.DGRAT__c', 
'SC_DD_Deal__c.EPS_Zone__c', 'SC_DD_Deal__c.ESR_Zone__c', 'SC_DD_Deal__c.Evaluation_Action__c', 'SC_DD_Deal__c.Expected_Profitability_Score__c', 
'SC_DD_Deal__c.Filtered_Revenue_Months__c', 'SC_DD_Deal__c.GSS_Product__c', 'SC_DD_Deal__c.GSS_Product_Name__c', 'SC_DD_Deal__c.LastModifiedById', 
'SC_DD_Deal__c.List_ESR__c', 'SC_DD_Deal__c.List_ESR_Local__c', 'SC_DD_Deal__c.List_Price__c', 'SC_DD_Deal__c.List_Price_Local__c', 'SC_DD_Deal__c.Local_Currency__c', 
'SC_DD_Deal__c.LOE_Id__c', 'SC_DD_Deal__c.Median_Profitability_Score__c', 'SC_DD_Deal__c.is_NAP_Customer__c', 'SC_DD_Deal__c.OwnerId', 'SC_DD_Deal__c.Package_Comp_Info__c', 
'SC_DD_Deal__c.Previous_Approver__c', 'SC_DD_Deal__c.Commented_By__c', 'SC_DD_Deal__c.Product_Type__c', 'SC_DD_Deal__c.PS_Avg_Non_Billable_Hours__c', 
'SC_DD_Deal__c.PS_Delivery_Cost__c', 'SC_DD_Deal__c.PS_Hours__c', 'SC_DD_Deal__c.PS_Hours_Per_Month__c', 'SC_DD_Deal__c.PS_Non_Billable_Hours__c', 
'SC_DD_Deal__c.PS_per_hour_cost__c', 'SC_DD_Deal__c.PS_Project_Budget_Hours__c', 'SC_DD_Deal__c.Requested_Hours__c', 'SC_DD_Deal__c.Requested_Price__c', 
'SC_DD_Deal__c.Requestor__c', 'SC_DD_Deal__c.Revenue_Months__c', 'SC_DD_Deal__c.SLA_Breached__c', 'SC_DD_Deal__c.SOCC_Hours_Per_Month__c', 'SC_DD_Deal__c.SOCC_Delivery_Cost__c', 
'SC_DD_Deal__c.SOC_Hours__c', 'SC_DD_Deal__c.SOCC_per_hour_cost__c', 'SC_DD_Deal__c.Total_Delivery_Cost__c', 'SC_DD_Deal__c.Total_Revenue_Unfiltered__c', 
'SC_DD_Deal__c.Total_Revenue_Filtered__c', 'SC_DD_Deal__c.Id', 'SC_DD_Deal__c.Account__r.Id', 'SC_DD_Deal__c.Account__r.AKAM_Account_ID__c', 'SC_DD_Deal__c.Account__r.Name', 
'SC_DD_Deal__c.Computed_ESR_Local__c', 'SC_DD_Deal__c.Approval_Stage__c'] ;  

// Message Codes and their config - Display Type(variant), title, mode 
export const ERROR_MSGS = {
    'NO_ACC_ACCESS': {  title: 'Outside your GRAZT',
                        message: 'Selected Account is outside your GRAZT. You can evaluate deals only within your GRAZT',
                        variant: 'error',
                        mode: 'sticky' },
    'ERR_DEAL_EVAL': { title: 'Deal Evaluation Error',
                    variant: 'error'},
    'ERR_DEAL_SAVE': { title: 'Error Saving Deal',
                    variant: 'error' },
    'ERR_DEAL_LOAD': { title: 'Error Loading Deal',
    variant: 'error' }
};

// Deal Calculation Type Message
export const CALC_MSG =  {
    'ACCOUNT': 'Cost trends at this account are used to calculate Expected Profitability Score',
    'GRAZT': 'Cost trends at similar GRAZT account are used to calculate Expected Profitability Score',
    'ESR': 'Cost trends not available to calculate Expected Profitability Score. Please use ESR to make decision'
};

export const DEAL_SOBJ_TYPE = 'SC_DD_Deal__c';