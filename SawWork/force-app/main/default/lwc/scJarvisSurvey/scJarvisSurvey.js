/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-11-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   11-30-2021   Vishnu Vardhan   Initial Version
**/
import { LightningElement, api } from 'lwc';
import getSurveyLink from '@salesforce/apex/ScJarvisSurvey.getSurveyInvitationLink';
import JV_Feedback from '@salesforce/label/c.JV_Feedback';

export default class ScJarvisSurvey extends LightningElement {

    surveyLink;

    @api surveyDevName;
    @api feedbackCategory;
    @api pageName;
    @api height;
    @api width;
    @api modalBgColor;


    // Flexi button Styling Info
    @api buttonLabel;
    @api buttonPosition; // normal, left, right
    @api buttonTextColor;
    @api butttonBgColor;
    @api buttonBgHoverColor;
    @api buttonBorderColor;
    @api buttonBorderRadius;
    @api buttonAlignment;
    @api buttonMargin;
    @api buttonHeight;
    @api buttonWidth;
    FEEDBACK = JV_Feedback;

    renderedCallback() {
        this.initCSSVariables();
    }

    get flexButtonLabel() {
        return !this.buttonLabel || this.buttonLabel === 'feedback'?  this.FEEDBACK : this.buttonLabel;
    }

    initCSSVariables() {

        this.setCssProperty('--jvSurveyContainerHeight', this.height - 200 + 'px');
        this.setCssProperty('--jvSurveyContainerWidth', this.width - 100 + 'px');
        this.setCssProperty('--jvSurveyHeight', this.height + 'px');
        this.setCssProperty('--jvSurveyWidth', this.width + 'px');
        this.setCssProperty('--modalBgColor', this.modalBgColor);

    }

    setCssProperty(cssPropName, cssValue) {
        if(cssValue) {
            const css = document.body.style;
            css.setProperty(cssPropName, cssValue)
        }
    }

    get currentPageUrl() {
        return window?.location?.href.replace(window.location.origin, '').split('?')[0].split('#')[0].substring(0, 254);
    }
    connectedCallback() {
        if (!this.surveyLink) {
            getSurveyLink({ surveyDeveloperName: this.surveyDevName, feedbackCategory: this.feedbackCategory, pageName: this.pageName || this.currentPageUrl })
                .then(result => {
                    console.log('getSurveyLink result ', result);
                    this.surveyLink = result;
                    // this.toggleModal(toggleId);
                })
                .catch(error => {
                    // TODO Error handling
                    console.log('getSurveyLink error ', error);
                });
        }
    }

    handleFlexiClick(ev) {
        const toggleId = ev.currentTarget.dataset.toggleid;
        this.toggleModal(toggleId);
    }
    handleIframeLoad() {
        this.initCSSVariables();
    }

    // Toggle Modal
    toggleModal(toggleId) {
        let modal = this.template.querySelector('[data-id="' + toggleId + '"');
        if (modal) {
            modal.toggle();
        }
    }

}