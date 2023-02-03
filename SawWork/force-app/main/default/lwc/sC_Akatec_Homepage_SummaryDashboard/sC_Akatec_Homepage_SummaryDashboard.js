/** @Date		:	June 20 2020
* @Author		: 	Sumukh SS 
*/
import { LightningElement } from 'lwc';
import getMyDashboardData from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getUserSummaryDashboardDetails';
import changehomeview from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.changeHomeView';

export default class SC_Akatec_Homepage_SummaryDashboard extends LightningElement {
    loadHeaderSpinner = false;
    ir_compliance;
    ir_compliance_color;
    caseupdate_compliance;
    res_sum_compliance;
    res_sum_compliance_color;
    loe_today;
    showcaseview = false;

    displaysummary = true;

    get viewFiltersOptions() {
        return [
            { label: 'Show Cases Only', value: 'Show Cases on Home' },
            { label: 'Show Escalations Only', value: 'Show Escalations on Home' },
            { label: 'Show Both', value: 'Show Both' }
        ];
    }

    viewFilter = 'Show Both';


    connectedCallback() {
        //loadStyle(this, resourceName + '/SC_Akatec_Lightning_Resource/SC_Akatec_Homepage.css')

        this.getDashDetails();
    }
    hideTable() {
        //this.showcaseview = false;
        this.displaysummary = !this.displaysummary;

    }

    showTable() {
        //this.showcaseview = true;
        this.displaysummary = !this.displaysummary;

    }
    onFilterChange(e) {
        this.loadHeaderSpinner = true;

        changehomeview({
            viewname: e.detail.value
        })
            .then(result => {
                window.location.reload(true);
            }).catch(error => {
                console.log(JSON.stringify(error));
            });

    }
    getDashDetails() {
        this.loadHeaderSpinner = true;
        getMyDashboardData({})
            .then(result => {
                this.loadHeaderSpinner = false;
                this.ir_compliance = result.ir_compliance;
                this.caseupdate_compliance = result.caseupdate_compliance;
                this.res_sum_compliance = result.res_sum_compliance;
                //this.res_sum_compliance_color=result.res_sum_compliance_color;
                this.loe_today = result.loe_today;
                this.viewFilter = result.akatecHomeView;
                //this.ir_compliance_color=result.ir_compliance_color;

                if (this.viewFilter === 'Show Escalations on Home')
                    this.showcaseview = false;
                else
                    this.showcaseview = true;

            }).catch(error => {
                this.loadHeaderSpinner = false;
                console.log(JSON.stringify(error));
            });
    }
}