import {publish} from "lightning/messageService";
import messageChannel from "@salesforce/messageChannel/scPageLayoutButtonOpen__c";

function openCustomButton(messageContext,actionName){
    publish(messageContext,messageChannel,{actionName});
}

export default openCustomButton