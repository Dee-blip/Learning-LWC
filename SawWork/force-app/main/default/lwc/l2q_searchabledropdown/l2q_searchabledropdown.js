/*
Author : Rajesh Kumar - GSM Sales Team .
JIRA : # SFDC-7368	
Description : Re-Usable Picklist component with inline search .
Consideration : Clients needs to hanlde error message based on data communication.
The IDs that you define in HTML templates may be transformed into globally unique values when the template is rendered. If you use an ID selector in JavaScript, it won’t match the transformed ID for that reason rendered callback is used
*/
import { LightningElement, api } from "lwc";
export default class L2q_searchabledropdown extends LightningElement {
  @api values = [];
  @api label = "";
  @api name = "";
  @api required = false;
  @api placeholder = "--None--";
  @api preSelect = "";
  @api dropdownStyle = "width:100%";
  @api uniquekey = '';
  @api disabled = false;
  @api autocomplete = 'off';

  initialized = false;
  renderedCallback() {
    if (this.initialized) {
      return;
    }
    this.initialized = true;
    let listId = this.template.querySelector("datalist").id;
    this.template.querySelector("input").setAttribute("list", listId);
  }
  handleValuechange(evt) {
    let sendParams = {
      uniquekey: this.uniquekey,
      selectedvalue: evt.target.value
    };
    const selectedEvent = new CustomEvent('selected', {
      detail: sendParams
    });
    this.dispatchEvent(selectedEvent);
  }
}