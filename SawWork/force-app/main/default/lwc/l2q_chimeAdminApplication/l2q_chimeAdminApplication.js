/**
*  @Date		:	April 15 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Application for selection of products for Chime Questionanaire Creation
*/
import { track,api, LightningElement } from 'lwc';

export default class L2q_chimeAdminApplication extends LightningElement {

    @track showProductSelection = true;
    @track showQuestionnaireAdmin = false;
    @track productId;

    @api isadmin=false;

    connectedCallback(){
        this.isadmin = true;
    }

    handleProductSelection(event) {
        this.productId = event.detail.productid;
        this.showProductSelection = false;
        this.showQuestionnaireAdmin = true;
    }
}