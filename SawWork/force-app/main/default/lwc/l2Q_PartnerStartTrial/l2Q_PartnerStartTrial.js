/**
 * Author:Rajesh Kumar
 * JIRA: SFDC-6634
 * Description : Below method handles error/redirect operation for partners in lightning mode : There is logic for internal user as well but that is currently not used.
 */
import { LightningElement, api } from 'lwc';
import findRecords from '@salesforce/apex/MarketPlaceContactRoleController.checkPartnerredirect';
import { NavigationMixin } from 'lightning/navigation';
export default class L2Q_PartnerStartTrial extends NavigationMixin(LightningElement) {
	@api recordId;
	processingComplete = false;
	isError = false;
	issystemError = false;
	richtext;
	processingText = 'Processing Request...';
	counter;
	redirectionMessage = '';
	intialtextClass;
	processingtextClass = 'slds-hide';
	error;
	connectedCallback() {
		this.doapexCall();
	}
	doapexCall() {
		findRecords({ objectrecordId: this.recordId, caller: 'lightning' })
			.then((result) => {
				if (result.isPartner == true) {
					if (result.isValid == false) {
						this.processingComplete = true;
						this.isError = true;
						let errorDetail = '<div style = "color :#c23934">' + result.erroMessage + '</div>';
						this.richtext = errorDetail;
					} else {
						this.counter = result.count;
						this.redirectionMessage = result.redirectionMessage;
						this.intialtextClass = 'slds-hide';
						this.processingtextClass = 'slds-show';
						this.checkredirectInterval(result.redirectionURL);
					}
				} else {
					const internalNavevent = new CustomEvent('internalnav', {
						detail: {
							data: {
								objectId: this.recordId,
								redirectionURL: result.redirectionURL,
								errorMessage: result.erroMessage,
								objectType: result.objectType
							}
						}
					});
					this.dispatchEvent(internalNavevent);
				}
			})
			.catch((error) => {
				console.log('error>>' + JSON.stringify(error));
				this.processingComplete = true;
				this.isError = false;
				this.error = error;
			});
	}
	checkredirectInterval = (navLink) => {
		var self = this;
		var refreshId = setInterval(() => {
			// used setinterval Web API instead of setTimeout to show page redirection message every second to the end user only if required .
			var count = self.counter - 1;
			self.counter = count <= 0 ? 0 : count;
			if (count <= 0) {
				clearInterval(refreshId);
				self.coloseQuickaction();
				window.open(navLink, '_blank');
			}
		}, 1000);
	};
	coloseQuickaction = () => {
		const closeQA = new CustomEvent('closeaction');
		this.dispatchEvent(closeQA);
	};
}