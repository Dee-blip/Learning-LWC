/* eslint-disable no-undef */
/**
* Author : Rajesh Kumar - GSM Sales Team
 * JIRA : # SFDC-7368
 * Description :   LWC Component for handling country wise allocation and approval
 * Consideration : 1.JSON.parse(JSON.Stringyfy(object)) is used to copy object removing refrences https://www.javascripttutorial.net/object/3-ways-to-copy-objects-in-javascript/
 *                 2.For Data Communication for object String form is used we can use deep clone and pass the object as well
 *                   LWC Best Practices :- https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.events_best_practices
 *                 3. If there is large data convert lifecycle async/await with normal promise chain to avoid peroformance issue : https://github.com/salesforce/eslint-plugin-lwc/blob/master/docs/rules/no-async-await.md
 *                 4. Row specific unique key is used instead of index ..because if data is sorted or re-arranged index value may give incorrect result .
 *                 5. While using arrow => functions please be careful about this context it takes our context not the inner one ES6 Feature .
 *                 6. Use async/await in component lifecycle only and only when you have neccessity to wait for result and you need single thread for the process | However it does not affect async transactions
 * @todo :  1.Take country list once and cache it at UI only issue(Corner case in middle if some one add the country) || Parked it for later discussed with BSA 
 *          2.Destructuring input api for better component performance when data is large - This is for future ehnacement if data set will be more than 1000
 *          Current Release Todo :
 */
import lodash from '@salesforce/resourceUrl/lodashjs'; // importing lodash for upcoming releases to handle large array manipulations | More Detail https://lodash.com 
import { loadScript } from 'lightning/platformResourceLoader';
import { LightningElement, track, api } from "lwc";
// eslint-disable-next-line no-unused-vars
import { generateuniqueKey, isEmpty, strOf, removeItem, returnAfterassignmnet } from "c/l2QlwcUtil";
import getAllocations from "@salesforce/apex/L2Q_CapacityRequestController.getallocatedCapacity";
import getcountryList from "@salesforce/apex/L2Q_CprUtil.getCountrydependentList";
import getctryMapping from "@salesforce/apex/L2Q_CprUtil.getCPRcountryvalidMapping";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class L2q_capacityallocation extends LightningElement {

  /*-----Begin API i/o Specifications----*/
  // Note : For generic component we can use structuring and destructuring of api object for single point of input (De-Structuring might take some millsecond browser time but eassy to handle)
  @api parentrecid = "";
  @api parentunqid = "";
  @api region = "";
  @api inputcountrysplit = ''; // Stringified object deep clone no-reference :- ponit 2 consideration
  @api forapproval = false;
  /*-----End API i/o Specifications----*/

  /****-Module Seprator-****/

  /*-----Begin tracked property----*/
  @track localdata = [];
  @track savedrecs = [];
  @track changedrecs = [];
  @track countryList = [];
  @track inputdata = [];
  @track countryMap = [];
  @track validMap = []; // new changes
  /*-----End tracked property----*/

  /****-Module Seprator-****/

  /*-----Begin local property----*/
  updatedisabled = false;
  isloading = false;
  scriptloaded = false;
  deletekey = new Set();
  /*-----End local property----*/

  /*----Begin Lifecycle hooks-----*/
  async connectedCallback() {
    this.inputdata = isEmpty(this.inputcountrysplit) ? [] : JSON.parse(this.inputcountrysplit); // comment : avoid setting puplic property use local as clone of public 
    this.isloading = true;
    this.retrieveCtrMapping();
    // prepare country list region wise :- This is apex call since request response is not high , else if there is server overload LWC native method can be used | Can be cached at UI will do in coming release
    try {
      let crList = await getcountryList();
      this.countryList = (crList[this.region]) ? crList[this.region] : [];
      if (this.countryList.length > 0) {
        this.countryList.forEach(el => {
          let obj = {};
          obj.key = el;
          obj.value = el;
          this.countryMap.push(obj);
        })
      }
    }
    catch (error) {
      this.isloading = false;
      this.showToastmessage('COUNTRY FETCH ERROR :- ', 'DETAIL: ' + JSON.stringify(error), 'error'); // we are not stopping code execution However error chances will never occur all the picklist will have value
    }
    //check if existing data exists for CPR Allocations based on parent recordid
    if (!isEmpty(this.parentrecid)) {
      try {
        this.savedrecs = await getAllocations({ parentId: this.parentrecid, region: [this.region] });
      } catch (error) {
        this.showToastmessage('ALLOCATION FETCH ERROR :- ', 'DETAIL: ' + JSON.stringify(error), 'error');
        this.isloading = false;
        return;
      }
    }
    this.localdata = (this.savedrecs.length > 0) ? JSON.parse(JSON.stringify(this.preparelocalList(this.inputdata, this.savedrecs))) : JSON.parse(JSON.stringify(this.inputdata));
    this.localdata = this.ldorderBy(this.localdata, ['country'], ['asc']); // while loading sort by country asc using lodash 
    this.isloading = false;
  }
  // adding dependent library in renderedCallback
  renderedCallback() {
    if (!this.scriptloaded) { // avoid multiple script render calls
      this.scriptloaded = true;
      Promise.all([
        loadScript(this, lodash + '/lodash/4.17.15/lodash.js') // lodash script
      ])
        .then(() => {
          console.log('script load success:)');
        })
        .catch(error => {
          console.log('script load erorr :(' + JSON.stringify(error));
        });
    }
  }
  /*----End Lifecycle hooks-----*/

  /**UTIL Server Calls //UAT Feedbacks */
  retrieveCtrMapping() {
    getctryMapping().then((result) => {
      // eslint-disable-next-line no-alert
      let data = JSON.parse(result);
      this.validMap = data.validlist;
    }).catch((error => {
      console.log('Mapping fetch error::' + JSON.stringify(error.message))
    }))
  }
  /**End UTIL Server Calls */

  /****-Module Seprator-****/

  /*----Begin @api methods-----*/
  @api
  addallocations() { // invoking add allocation for country
    try {
      this.localdata.push(this.rowIntializer(this.parentrecid, this.parentunqid, this.region, '', '', '0', '0'));
    } catch (error) {
      this.showToastmessage('ADD ALLOCATION ERROR :- ', 'DETAIL: ' + error.message, 'error');
    }
  }

  @api
  updateRecord() {
    if (this.requestcheckValidation()) {
      this.verifychangedData();
      this.removedeleted();
      this.dispatchUpdateddata(this.changedrecs.length > 0 ? JSON.stringify(this.changedrecs) : '', this.getrollupSum(this.localdata, 'request'));
    }
  }

  //handle record approval
  @api
  handleApproval() {
    try {
      let savedData = JSON.parse(JSON.stringify(this.savedrecs));
      let changedData = (this.inputdata.length > 0) ? JSON.parse(JSON.stringify(this.inputdata)) : [];
      let sum = 0;
      this.localdata.forEach(el => {
        sum = sum + parseFloat(el.approvedcapacity, 10);
        let changedIndex = this.ldfindIndex(changedData, { 'recordid': el.recordid });
        let savedIndex = this.ldfindIndex(savedData, { 'recordid': el.recordid });
        changedData = (changedIndex >= 0) ? (parseFloat(savedData[savedIndex].approvedcapacity, 10) === parseFloat(el.approvedcapacity, 10) ? removeItem(changedData, changedIndex) : returnAfterassignmnet(changedData, changedIndex, 'approvedcapacity', el.approvedcapacity)) : (savedData[savedIndex].approvedcapacity !== el.approvedcapacity) ? this.ldconcat(changedData, JSON.parse(JSON.stringify(el))) : changedData;
      });
      if (this.handleapprovalValidation(this.localdata)) {
        this.dispatchUpdateddata(changedData.length > 0 ? JSON.stringify(changedData).replace(/\\/g, '') : '', sum);
      }
    } catch (err) {
      this.showToastmessage('APPROVAL ALLOCATION ERROR :- ', 'DETAIL: ' + err.message, 'error');
    }

  }
  @api
  rowIntializer(parentrecid = '', parentunqid = '', region = '', recordid = '', country = '', allocatedcapacity = '0', approvedcapacity = '0') {
    var Obj = {
      parentrecid: parentrecid,
      parentunqid: parentunqid,
      recordid: recordid,
      rowunqid: generateuniqueKey(),
      country: country,
      allocatedcapacity: allocatedcapacity,
      approvedcapacity: approvedcapacity,
      region: region,
      index: 0
    };
    return Obj;
  }
  /*----End @api methods-----*/

  /****-Module Seprator-****/

  /*----Begin update/change/delete methods-----*/
  handleallocationChange(evt) {
    try {
      let targetId = evt.target.dataset.targetId;
      let value = evt.target.value;
      this.localdata[this.localdata.findIndex(el => { return el.rowunqid === targetId; })].allocatedcapacity = value;
    } catch (error) {
      this.showToastmessage('REQUEST ALLOCATION CHANGE SYSTEM ERROR :- ', 'DETAIL: ' + error.message, 'error');
    }
  }
  // handle approval change | using rowkey instead of index to avoid incorrect result 
  handleapprovalChange(evt) {
    try {
      let targetId = evt.target.dataset.targetId;
      let value = evt.target.value;
      let index = this.localdata.findIndex(el => { return el.rowunqid === targetId; });
      this.localdata[index].approvedcapacity = value;
    }
    catch (error) {
      this.showToastmessage('APPROVAL ALLOCATION CHANGE SYSTEM ERROR :- ', 'DETAIL: ' + error.message, 'error');
    }
  }
  // handle country change | using rowkey instead of index to avoid incorrect result 
  handleCountrychange(evt) {
    try {
      let detail = evt.detail;
      this.localdata[this.localdata.findIndex(el => { return el.rowunqid === detail.uniquekey; })].country = detail.selectedvalue;
    } catch (error) {
      this.showToastmessage('COUNTRY CHANGE SYSTEM ERROR :- ', 'DETAIL: ' + error.message, 'error');
    }
  }

  handleDelete(evt) {
    let rowkey = evt.target.dataset.targetId;
    this.deletekey.add(rowkey);
    let index = this.localdata.findIndex(el => {
      return el.rowunqid === rowkey;
    })
    if (index !== -1) {
      this.localdata.splice(index, 1);
    }
  }
  /*----End update/change/delete methods-----*/

  /****-Module Seprator-****/

  /*----Begin local/native/common methods-----*/
  // method handles to prepare list beween intersection of current buffer data and server data  | There may be chance that already unsaved data is stored to parent scroll and then find intersection
  preparelocalList(inputdata, savedrecs) {
    var returnArr = [];
    if (inputdata.length < 1) {
      savedrecs.forEach(el => {
        returnArr.push(this.rowIntializer(this.parentrecid, this.parentunqid, this.region, el.recordid, el.country, el.allocatedcapacity, el.approvedcapacity));
      });

    } else {
      let tempData = [];
      let mp = new Map();
      inputdata.forEach(el => {
        if (!isEmpty(el.recordid)) {
          mp.set(el.recordid, el);
        }
      })
      savedrecs.forEach(el => {
        if (!mp.has(el.recordid)) {
          tempData.push(this.rowIntializer(this.parentrecid, this.parentunqid, this.region, el.recordid, el.country, el.allocatedcapacity, el.approvedcapacity));
        }
      })
      returnArr = inputdata.concat(tempData);
    }
    return returnArr;
  }

  // Method to handle request allocation validation country wise
  requestcheckValidation = () => {
    let cList = [];
    if (this.localdata.length > 0) {
      for (let i = 0; i < this.localdata.length; i++) {
        let el = this.localdata[i]; // note for-Each can't be cancelled
        let row = i + 1;
        if (isEmpty(el.country.trim())) {
          this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : Country is missing.', 'error');
          return false;
        }
        if (isNaN(parseFloat(el.allocatedcapacity))) {
          this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : Requested capacity is missing.', 'error');
          return false;
        }
        if (!isEmpty(el.country) && !(this.countryList.length > 0 ? this.countryList.includes(el.country.trim()) : false)) { // country is intialized with '' no null exception
          this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : Please select a valid country to proceed.', 'error');
          return false;
        }
        if (!isEmpty(el.country) && cList.includes(el.country.trim())) {
          this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : Duplicate request allocation for country ' + el.country, 'error');
          return false;
        }
        else if (!isEmpty(el.country)) {
          cList.push(el.country.trim());
        }
        //Begin UAT Feedback new changes 
        if (this.validMap.length > 0) {
          let data = this.validMap[this.findpropIndex(this.validMap, this.region)].value;
          let all = data[0];
          let rest = data[1];
          if (cList.includes(all) && this.localdata.length > 1) {
            this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : While selecting All ' + this.region + ' other value cannot be selected', 'error');
            return false;
          }
          if (cList.includes(rest) && this.localdata.length === 1) {
            this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : While selecting Rest of ' + this.region + ', you must add atleast one country.', 'error');
            return false;
          }
        }
        //End UAT Feedback new changes 
      }

    }
    return true;
  }

  verifychangedData = () => {
    if (this.savedrecs.length < 1) { // if there is no server record then copy local scroll date to changed data clone it without reference
      this.changedrecs = JSON.parse(JSON.stringify(this.localdata));
    }
    else {
      // prepare map to hold server data
      let saveRecmap = new Map();
      this.savedrecs.forEach(el => {
        saveRecmap.set(el.recordid, el);
      })

      // if input data length is zero and there is changes against server or local data track for changes
      if (this.inputdata.length < 1) {
        this.changedrecs = [];
        this.localdata.forEach(el => {
          //if changes in server data track for change
          if (!isEmpty(el.recordid) && saveRecmap.has(el.recordid) && (el.country !== saveRecmap.get(el.recordid).country || el.allocatedcapacity !== saveRecmap.get(el.recordid).allocatedcapacity)) {
            this.changedrecs.push(el);
          }
          // if not server data and its new track for change
          if (isEmpty(el.recordid)) {
            this.changedrecs.push(el);
          }
        })
      }
      // if changed input is greather than 0
      if (this.inputdata.length > 0) {
        this.changedrecs = JSON.parse(JSON.stringify(this.inputdata)); // clone without reference
        // manage data for changed record
        this.localdata.forEach(el => {
          this.managecaddData(el.rowunqid, el); //prepare changes data
        })
        // manage data for changed record back to orgin value and its already in database ;
        this.localdata.forEach(el => {
          if (!isEmpty(el.recordid) && saveRecmap.has(el.recordid) && (el.country === saveRecmap.get(el.recordid).country && parseFloat(el.allocatedcapacity, 10) === parseFloat(saveRecmap.get(el.recordid).allocatedcapacity, 10))) { // use strOf only if you want to treat undefined and null as ''
            this.managechangedData(el.recordid);
          }
        })
      }
    }
    return this.changedrecs;
  }
  // for handling the manged data
  managechangedData(recordid) {
    let index = this.changedrecs.findIndex(el => {
      return el.recordid === recordid;
    })
    if (index !== -1) {
      this.changedrecs.splice(index, 1)
    }
  }

  // function to verify changed data without recid
  managecaddData(rowunqid, data) {
    let index = this.changedrecs.findIndex(el => {
      return el.rowunqid === rowunqid;
    })
    if (index === -1) {
      this.changedrecs.push(JSON.parse(JSON.stringify(data)));
    } else {
      if (this.changedrecs[index].allocatedcapacity !== data.allocatedcapacity || this.changedrecs[index].country !== data.country) {
        this.changedrecs[index] = JSON.parse(JSON.stringify(data))
      }
    }
  }
  removedeleted() {
    this.changedrecs = (this.deletekey.size > 0 && this.changedrecs.length > 0) ? this.changedrecs.filter(el => !this.deletekey.has(el.rowunqid)) : this.changedrecs;
  }
  // While Approving check for some validation
  handleapprovalValidation(data) {
    let sum = 0;
    if (data.length < 1) {
      this.showToastmessage('Error : ', 'There is no data to update.', 'error');
      return false;
    }
    for (let i = 0; i < data.length; i++) {
      let row = i + 1;
      sum = sum + data[i].approvedcapacity;
      if (isNaN(parseFloat(data[i].approvedcapacity))) {
        this.showToastmessage('ERROR AT ROW NO : ' + row, 'DETAIL : Approved capacity is missing.', 'error');
        return false;
      }
      if (data[i].approvedcapacity < 0) {
        this.showToastmessage('ERROR AT ROW NO : ' + row, 'Approved capacity must be non-negative value.', 'error');
        return false;
      }

    }
    if (sum <= 0) {
      this.showToastmessage('ERROR: ', 'Sum of approved capacity must be greater than 0.', 'error');
      return false;
    }
    return true;
  }

  // get roll up sum
  getrollupSum(inputArr = this.localdata, type) {
    let sum = 0;
    inputArr.forEach(el => {
      let allocReq = isEmpty(el.allocatedcapacity) ? '0' : el.allocatedcapacity;
      let appReq = isEmpty(el.approvedcapacity) ? '0' : el.approvedcapacity;
      sum = (type === 'request') ? sum + parseFloat(allocReq) : sum + parseFloat(appReq);
    })
    return sum;
  }

  showToastmessage(title = 'TOAST NOTIFICATION !', message = 'Unexpected error ', variant = 'info', mode = 'dismissable') { //@todo Needs to moved to LWC Common Util 
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: mode
    });
    this.dispatchEvent(evt);
  }
  // Begin UAT feedback
  findpropIndex = (arr, propName) => {
    return arr.findIndex(el => { return el.region === propName; })
  }
  // End UAT feedback

  /*----End local/native/common methods-----*/

  /****-Module Seprator-****/

  /*----Begin Event Dispatcher-----*/
  dispatchUpdateddata(data, sum) { // bubble up event   
    try {
      let response = {
        childval: data.replace(/\\/g, ''), // replace unwanted character | There was an issue while sending an object serializing it before send
        sum: sum,
        region: this.region,
        parentrecid: this.parentrecid,
        parentunqid: this.parentunqid,
        forapproval: this.forapproval
      }
      const selectedEvent = new CustomEvent('childchanged', {
        detail: {
          response: response
        }
      });
      this.dispatchEvent(selectedEvent);
    } catch (err) {
      this.showToastmessage('ALLOCATION EVENT BUBBLE ISSUE :- ', 'DETAIL: ' + err.message, 'error');
    }
  }
  /*----End Event Dispatcher-----*/
  /****-Module Seprator-****/
  /*----Begin getters-----*/ // Note : use getters for rendered data based on conditional logic else local property would work 
  get datalist() {
    let data = this.localdata;
    data.forEach((el, index) => {
      el.index = index + 1;
    })
    return data;
  }

  get showsum() {
    return (this.localdata.length > 0) ? true : false;
  }
  get reqsum() {
    return 'TOTAL : ' + this.getrollupSum(this.localdata, 'request');
  }
  get apprsum() {
    return 'TOTAL : ' + this.getrollupSum(this.localdata, '!request');
  }
  /*----End getters-----*/
  /****-Module Seprator-****/

  /*----Begin setters-----*/
  /*----Begin setters-----*/
  /****-Module Seprator-****/


  /*---Begin External Library Functions----*/ //@todo Needs to be moved to Common Util LWC | As of now direct invocation should be fine 
  ldorderBy(data, fieldDetail, order) {
    // eslint-disable-next-line no-undef
    return _.orderBy(data, fieldDetail, order);
  }
  ldfindIndex(data, criteria) {
    // eslint-disable-next-line no-undef
    return _.findIndex(data, criteria)
  }
  ldconcat(arr, val) {
    return _.concat(arr, val);
  }
  /*---End External Library Functions----*/
}