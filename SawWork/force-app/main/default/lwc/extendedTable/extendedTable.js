import LightningDatatable from 'lightning/datatable';
import scSoccViewInstruction from './scSoccViewInstruction.html';
import scSoccActionInstruction from './scSoccActionInstruction.html';
import scSoccRevokeInstruction from './scSoccRevokeInstruction.html';


export default class ExtendedTable extends LightningDatatable {
     static customTypes = {
          scSoccViewInstruction:{
               template: scSoccViewInstruction,
               typeAttributes: ['insId', 'insName']
          },
          scSoccActionInstruction: {
               template: scSoccActionInstruction,
               typeAttributes: ['insId']
          },
          scSoccRevokeInstruction: {
               template: scSoccRevokeInstruction,
               typeAttributes: ['insId']
          }
          
     };
}