import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export function getPageReference(cmp, objectApiName, recordTypeId) {
    const defaultValues = encodeDefaultFieldValues({
        Case__c: cmp.recordId
    });
    return {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'new'
            },
            state: {
                recordTypeId:recordTypeId,
                defaultFieldValues: defaultValues,
                inContextOfRef: '1.' + window.btoa(JSON.stringify(cmp.pageRef))
            }
        };
}

export function extractRecordTypeIdFromObjInfo(objInfo, rtName) {
    const rtInfo = Object.values(objInfo.recordTypeInfos).find(rt => {
        return rt.name === rtName;
    });
    return rtInfo.recordTypeId;
}