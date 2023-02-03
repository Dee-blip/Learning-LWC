import TAB_MY_OPEN from '@salesforce/label/c.JV_MyActiveCases';
import TAB_ALL_OPEN from '@salesforce/label/c.JV_AllActive';
import TAB_MY_CLOSED from '@salesforce/label/c.JV_MyClosed';
import TAB_ALL_CLOSED from '@salesforce/label/c.JV_AllClosed';
import LB_DISPLAYED_ACTIVE_CASES from '@salesforce/label/c.JV_DisplayedActiveCases';
import LB_DISPLAYED_CLOSED_CASES from '@salesforce/label/c.JV_DisplayedClosedCases';
import STAB_TECH from '@salesforce/label/c.JV_TechnicalTab';
import STAB_SOCC from '@salesforce/label/c.JV_SoccTab';
import STAB_BILLING from '@salesforce/label/c.JV_BillingTab';
import STAB_PS from '@salesforce/label/c.JV_ProfServTab';
import STAB_AMG from '@salesforce/label/c.JV_AmgTab';
import STAB_ALL from '@salesforce/label/c.JV_AllTab';
import LB_SELECTED_ACC from '@salesforce/label/c.JV_SelectedAcc';
import LB_COLS_SEARCH from '@salesforce/label/c.JV_ColumnSearch';
import LB_SELECT_ALL from '@salesforce/label/c.JV_SelectAll';
import LB_CLEAR_ALL from '@salesforce/label/c.JV_ClearAll';
import LB_ALL_CASES from '@salesforce/label/c.JV_AllCases';
import LB_REFRESHED from 	'@salesforce/label/c.JV_Refreshed';
import LB_CASES from '@salesforce/label/c.JV_Cases';
import LB_ACCOUNT from '@salesforce/label/c.Jarvis_CaseLabel_Account';
import LB_ACCOUNT_REQ_ERROR from '@salesforce/label/c.JV_AccountError';
import LB_NEW_CASE from '@salesforce/label/c.JV_NewCase';
import LB_ALL_ACCOUNTS from '@salesforce/label/c.JV_AllAccounts';
import LB_ACC_SELECTED from '@salesforce/label/c.JV_AccSelected';
import LB_ACC_FILTER_ACTIVE from '@salesforce/label/c.JV_AccFilterActive';
import LB_DISMISS from '@salesforce/label/c.JV_Dismiss';
import LB_REMOVE_FILTER from '@salesforce/label/c.JV_RemoveFilter';
import LB_ERR_SELECT_COLUMN from '@salesforce/label/c.JV_ErrSelectColumn';
import LB_SEARCH_THIS_LIST from '@salesforce/label/c.JV_SearchList';
import LB_EXPORT_LIST from '@salesforce/label/c.JV_ExportList';
import LB_REFRESH_LIST from '@salesforce/label/c.JV_RefreshList';
import LB_NO_RESULTS from '@salesforce/label/c.JV_NoSearchResults';
import LB_NO_RECORDS from '@salesforce/label/c.JV_NoRecords';
import LB_COL_PREVIEW from '@salesforce/label/c.Jarvis_Preview';
import LB_COL_CASE_ID from '@salesforce/label/c.Jarvis_CaseLabel_Case_ID';
import LB_COL_PD_NAME from '@salesforce/label/c.Jarvis_CaseLabel_PD_Name';
import LB_COL_CASE_TYPE from '@salesforce/label/c.Jarvis_CaseLabel_Case_Type';
import LB_COL_CUSTOMER_CONTACT from '@salesforce/label/c.Jarvis_CaseLabel_Customer_Contact';
import LB_COL_ACCOUNT from '@salesforce/label/c.Jarvis_CaseLabel_Account';
import LB_COL_SEVERITY from '@salesforce/label/c.Jarvis_CaseLabel_Severity';
import LB_COL_SUBJECT from '@salesforce/label/c.Jarvis_CaseLabel_Subject';
import LB_COL_STATUS from '@salesforce/label/c.Jarvis_CaseLabel_Status';
import LB_COL_CREATED_DATE from '@salesforce/label/c.Jarvis_CaseLabel_Created_Date';
import LB_COL_UPDATED_DATE from '@salesforce/label/c.Jarvis_CaseLabel_Updated_Date';
import LB_ACC_PLACEHOLDER from '@salesforce/label/c.JV_AccountPlaceholder'; 
import LB_APPLY from '@salesforce/label/c.JV_Apply'; 
import LB_CANCEL from '@salesforce/label/c.Jarvis_Button_Cancel'; 

export const LABELS = {
    TAB_MY_OPEN,
    TAB_ALL_OPEN,
    TAB_MY_CLOSED,
    TAB_ALL_CLOSED,
    STAB_TECH,
    STAB_SOCC,
    STAB_BILLING,
    STAB_PS,
    STAB_AMG,
    STAB_ALL,
    LB_SELECTED_ACC,
    LB_COLS_SEARCH,
    LB_APPLY,
    LB_CANCEL,
    LB_SELECT_ALL,
    LB_CLEAR_ALL,
    LB_CASES,
    LB_ACCOUNT,
    LB_ALL_CASES,
    LB_REFRESHED,
    LB_ACCOUNT_REQ_ERROR,
    LB_NEW_CASE,
    LB_ALL_ACCOUNTS,
    LB_ACC_SELECTED,
    LB_ACC_FILTER_ACTIVE,
    LB_DISMISS,
    LB_REMOVE_FILTER,
    LB_ERR_SELECT_COLUMN,
    LB_SEARCH_THIS_LIST,
    LB_EXPORT_LIST,
    LB_REFRESH_LIST,
    LB_NO_RESULTS, 
    LB_NO_RECORDS,
    LB_COL_PREVIEW,
    LB_COL_CASE_ID,
    LB_COL_PD_NAME,
    LB_COL_CASE_TYPE,
    LB_COL_CUSTOMER_CONTACT,
    LB_COL_ACCOUNT,
    LB_COL_SEVERITY,
    LB_COL_SUBJECT,
    LB_COL_STATUS,
    LB_COL_CREATED_DATE,
    LB_COL_UPDATED_DATE,
    LB_ACC_PLACEHOLDER,
    LB_DISPLAYED_ACTIVE_CASES,
    LB_DISPLAYED_CLOSED_CASES
};

export class TabLabels {
    updateCount(dashInfo) {
        this.lbSubTabAll = this.getTabLabel(STAB_ALL, dashInfo.caseList.length);
        this.lbSubTabTechnical = this.getTabLabel(STAB_TECH, dashInfo.techCasesCount);
        this.lbSubTabSocc = this.getTabLabel(STAB_SOCC, dashInfo.soccCasesCount);
        this.lbSubTabBilling = this.getTabLabel(STAB_BILLING, dashInfo.billingCasesCount);
        this.lbSubTabPs = this.getTabLabel(STAB_PS, dashInfo.psCasesCount);
        this.lbSubTabAmg = this.getTabLabel(STAB_AMG, dashInfo.amgCasesCount);

        this.lbTabAllOpen = this.getTabLabel(TAB_ALL_OPEN, dashInfo.allOpenCasesCount);
        this.lbTabAllClosed = this.getTabLabel(TAB_ALL_CLOSED, dashInfo.allClosedCasesCount);
        this.lbTabMyClosed = this.getTabLabel(TAB_MY_CLOSED, dashInfo.myClosedCasesCount);
        this.lbTabMyOpen = this.getTabLabel(TAB_MY_OPEN, dashInfo.myOpenCasesCount);
    }

    getTabLabel(tabName, count) {
        return `${tabName} (${count || 0})`;
    }
}