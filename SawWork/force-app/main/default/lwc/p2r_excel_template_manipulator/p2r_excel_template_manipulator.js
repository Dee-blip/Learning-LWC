/*
Developer @ Hemant Barapatre
purpose: To generate the excel on the fly on the LWC component
Template: Apex Class/Trigger Template/LWC component

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 29/08/2020

Base Line : Used as a part of dynamic Excel Generation feature for CPQ/HD

Purpose : To get the data for dynamic section generation

Usage : used as an implementation for P2r_excel_template_manipulator.

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

component Associated : [ P2r_excel_template_manipulator ]
Class used : P2r_Excel_Template_Manipulator

*/

import { LightningElement, track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
// import classObject from "@salesforce/apex/P2r_Excel_Template_Manipulator.classObject";

import exceljs from '@salesforce/resourceUrl/exceljs';
import { p2r_excel_simpleplain_template } from './p2r_excel_simpleplain_template';

export default class P2r_excel_template_manipulator extends LightningElement {
    @api recordId;
    @api recordobj; //pass the record object via @wire service only/imperative calls.
    @api objectlistofmaps = {};
    // the List of Maps is required here List<Map<String,List<sObject>>> ListofMAp = new List<Map<String,List<sObject>>>();
    @api title = 'Excel Document Generator';
    @track state = {
        //Uitilizing State based template generation *BEST PRACTICE*
        TEMPLATE_OPTIONS: [{ label: 'Simple Plain', value: 'Simple_Plain' }],
        SELECTED_TEMPLATE: 'Simple_Plain',
        TEMPLATE_META: {
            Simple_Plain: p2r_excel_simpleplain_template()
        }
    };

    get templateoptions() {
        // used in view
        return this.state.TEMPLATE_OPTIONS;
    } // getting template from state , the old way

    /*@wire(getRecord, { recordId: "$recordId", fields: FIELDS })
      currentrecord({ error, data }) {
        if (data) {
            this.recordobj = data;
            console.log('[data]'+ JSON.stringify(data.fields.Name));
        } else if (error) {
            console.log('[ERRROR] '+error);
        }
    }; */

    handleChange(event) {
        // Handler for Combobox/Piclist in this Component for Template selection
        let cloned_state = { ...this.state }; // used the principle on ummutabiity.
        cloned_state.SELECTED_TEMPLATE = event.detail.value;
        this.state = cloned_state;
        console.log('selected template' + this.state.SELECTED_TEMPLATE);
    }

    renderedCallback() {
        // Calling Lighthing Lifecycle Hook during rendering
        Promise.all([
            loadScript(this, exceljs + '/xlsx-populate.min.js'),
            loadScript(this, exceljs + '/download.js'),
            loadScript(this, exceljs + '/base64.min.js')
        ])
            .then(() => {
                console.log('loaded successfully !');
            })
            .catch((error) => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:
                            'Error loading exceljs from P2r_excel_template_manipulator',
                        message: error,
                        variant: 'error'
                    })
                );
            });
    } //

    b64toBlob = (b64Data, contentType = '', sliceSize = 512) => {
        //specificaly desigend for the byte convertion on the fly in browser. :) PING ME for Conceptual understanding
        const byteCharacters = atob(b64Data);
        const byteArrays = [];

        for (
            let offset = 0;
            offset < byteCharacters.length;
            offset += sliceSize
        ) {
            const slice = byteCharacters.slice(offset, offset + sliceSize);

            const byteNumbers = new Array(slice.length);
            for (let i = 0; i < slice.length; i++) {
                byteNumbers[i] = slice.charCodeAt(i);
            }

            const byteArray = new Uint8Array(byteNumbers);
            byteArrays.push(byteArray);
        }

        const blob = new Blob(byteArrays, { type: contentType });
        return blob;
    }; //b64toBlob

    generateCurrentTemplateFile = () =>{
        try {
            //read the binary data from the template and create payload for  DOOM GUY :) please let it be i love DOOM game
            console.log(
                'reading from current template .... ->>' +
                    this.state.TEMPLATE_META[this.state.SELECTED_TEMPLATE]
            );
            const fileblob = this.b64toBlob(
                this.state.TEMPLATE_META[this.state.SELECTED_TEMPLATE]
                    .BINARY_DATA,
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            );
            //const fileblob = this.state.TEMPLATE_META[this.state.SELECTED_TEMPLATE].BINARY_DATA;
            //  console.log(fileblob);
            // console.log(JSON.stringify(this.recordobj.fields.Name));
            //generating the array

            let static_area = this.state.TEMPLATE_META[
                this.state.SELECTED_TEMPLATE
            ].TARGET_MAP.STATIC_AREA.map((row) => {
                //console.log(getFieldValue(this.recordobj,'Name'));
                // console.log(row.TARGET_CELL);
                return {
                    cell: row.TARGET_CELL,
                    value:
                        row.TYPE === 'dynamic'
                            ? this.recordobj.fields[row.TARGET_VALUE]
                                  .displayValue == null
                                ? this.recordobj.fields[row.TARGET_VALUE].value
                                : this.recordobj.fields[row.TARGET_VALUE]
                                      .displayValue
                            : row.TARGET_VALUE,
                    style: row.STYLE
                };
            });

            // total line generation;
            let total_line = this.state.TEMPLATE_META[
                this.state.SELECTED_TEMPLATE
            ].TARGET_MAP.ITERATIVE_AREA.reduce((result, iter) => {
                let total_column = Object.keys(iter.columns).filter((col) => {
                    return iter.columns[col].showTotal === true;
                });
                let total_column_info = {};
                total_column_info.columns = total_column;
                total_column_info.start = iter.rows.start;
                total_column_info.formula = iter.rows.totalFormula;
                total_column_info.firstColumn = iter.firstColumnValue;
                total_column_info.lastColumn = iter.lastColumnValue;
                return result.set(iter.objectkey, total_column_info);
            }, new Map());

            //Dymanic area Data Generation
            let iterative_area = this.state.TEMPLATE_META[
                this.state.SELECTED_TEMPLATE
            ].TARGET_MAP.ITERATIVE_AREA.map((r) => {
                let area_map = [];
                // let object_Key = r.objectkey;
                let columns = Object.keys(r.columns);
                let rows = Array.from(
                    Array(r.rows.end - r.rows.start + 1),
                    (_, i) => i + r.rows.start
                );
                // console.log(object_Key);
                // console.log(columns);
                area_map = rows.map((row_x) => {
                    let row_array = [];
                    columns.forEach((col_x) => {
                        let col = {};
                        col.cell = col_x + row_x;
                        col.apifield = r.columns[col_x].key;
                        col.style = r.columns[col_x].style;
                        col.objectkey = r.objectkey;
                        col.conditionalformatting = r.rows
                            .conditionalformatting
                            ? r.rows.conditionalformatting
                            : '';
                        col.conditionalformattingkey = r.rows
                            .conditionalformattingkey
                            ? r.rows.conditionalformattingkey
                            : '';
                        row_array.push(col);
                    });
                    return row_array;
                }); //areamap
                // console.log('I am here !!!')
                return area_map;
            });

            console.log(iterative_area);

            return (
                /* eslint-disable-next-line */
                XlsxPopulate.fromDataAsync(fileblob) // eslint-disable-line no-eval
                    .then(function (workbook) {
                        console.log('reading....');
                        // const sheet = workbook.activeSheet();
                        //console.log(sheet);
                        //START OF Template Data Feeding
                        //STATIC AREA
                        static_area.forEach((r) => {
                            workbook
                                .sheet(0)
                                .cell(r.cell)
                                .style(r.style ? r.style : {})
                                .value(r.value);
                                
                        });

                        return workbook;
                    })
                    .then((workbook) => {
                        //get Object Keys
                        let object_Keys = this.state.TEMPLATE_META[
                            this.state.SELECTED_TEMPLATE
                        ].TARGET_MAP.ITERATIVE_AREA.map((r) => {
                            return r.objectkey;
                        });
                        console.log(object_Keys);

                        object_Keys.forEach((obj) => {
                            // this.objectlistofmaps[obj].forEach((obj_key)=>{
                            // console.log(this.objectlistofmaps[obj].length);
                            iterative_area.forEach((cell_Obj) => {
                                cell_Obj
                                    .slice(0, this.objectlistofmaps[obj].length)
                                    .forEach((r_x, idx) => {
                                        r_x.forEach((c_x) => {
                                            workbook
                                                .sheet(0)
                                                .cell(c_x.cell)
                                                .style(
                                                    c_x.style ? c_x.style : {}
                                                )
                                                .style(
                                                    c_x.conditionalformatting(
                                                        this.objectlistofmaps[
                                                            obj
                                                        ][idx][
                                                            c_x
                                                                .conditionalformattingkey
                                                        ]
                                                    )
                                                )
                                                .value(
                                                    this.objectlistofmaps[obj][
                                                        idx
                                                    ][c_x.apifield] === 0.0
                                                        ? ''
                                                        : this.objectlistofmaps[
                                                              obj
                                                          ][idx][c_x.apifield]
                                                );
                                            
                                                let row = workbook.sheet(0).cell(c_x.cell).row();
                                                let column = workbook.sheet(0).cell(c_x.cell).column();
                                                let value = workbook.sheet(0).cell(c_x.cell).value();
                                                if (String(value).length > 20) {
                                                    workbook.sheet(0).cell(c_x.cell).style({ wrapText: true });
                                                            column.width(30);
                                                            row.height(30);
                                                }
                                        }); //c_x
                                    }); //r_x
                            }); //cell_Obj

                            let table_length = this.objectlistofmaps[obj]
                                .length;
                            let row_start = total_line.get(obj).start;
                            let row_end = row_start + table_length;
                            let range_string =
                                total_line.get(obj).firstColumn +
                                row_end +
                                ':' +
                                total_line.get(obj).lastColumn +
                                row_end;
                            workbook.sheet(0).cell(total_line.get(obj).firstColumn + row_end).value("Totals");
                            workbook.sheet(0).range(range_string).style({
                                bold: true,
                                fill: 'fefec7'
                            });
                            total_line
                                .get(obj)
                                .columns.forEach((column_name) => {
                                    workbook
                                        .sheet(0)
                                        .cell(column_name + row_end)
                                        .formula(
                                            total_line
                                                .get(obj)
                                                .formula(
                                                    column_name,
                                                    row_start,
                                                    row_end - 1
                                                )
                                        );
                                });
                            // });//obj_key
                        }); //obj

                        console.log('i am returning');
                        return workbook;
                    })
                    // .then((workbook) => {
                    //   //call download maple bear function :)
                    //   // Start of base64 factory to create the binary data ready for download
                    //   this.generateExcel(workbook);
                    // })
                    .catch((error) => {
                        let message =
                            'Error received: code' +
                            error.errorCode +
                            ', ' +
                            'message ' +
                            error;
                        console.log(message);
                        return null;
                    })
            );
        } catch (e) {
            console.log(e);
        }
        return null;
    } //generateCurrentTemplateFile()

    downloadfile = () => {
        // download  workbook function
        console.log('Download Clicked!!!!');
        let worb = this.generateCurrentTemplateFile();
        worb.then((wb) => {
            this.generateExcel(wb);
        }).catch((error) => {
            let message =
                'Error received: code ' +
                error.errorCode +
                ', ' +
                'message ' +
                error;
            console.log(message, error);
            return null;
        });
    }; //download

    @api excelpayload() {
        console.log('Providing payload');
        let worb = this.generateCurrentTemplateFile();
        //  return 'Haggu';
        return worb
            .then((wb) => {
                return wb
                    .outputAsync('base64')
                    .then((base64) => {
                        let payload = {};
                        console.log('genrating JSON File ....');
                        /* eslint-disable-next-line */
                        payload.base64 = Base64.toUint8Array(base64); // eslint-disable-line no-eval
                        payload.filename = 'filename.xlsx';
                        return payload;
                    })
                    .then((data) => {
                        //  console.log(data);
                        return data;
                    }); //then
            })
            .catch((error) => {
                let message =
                    'Error received: code ' +
                    error.errorCode +
                    ', ' +
                    'message ' +
                    error;
                console.log(message);
                return null;
            });
    } //excelpayload

    generateExcel = (workbook) => {
        // Small Utiltiy method for doenloading Bytes version if File.
        // Start of base64 factory to create the binary data ready for download
        workbook.outputAsync('base64').then((base64) => {
            console.log('Downloading File ....');
            /* eslint-disable-next-line */
            download(
                /* eslint-disable-next-line */
                Base64.toUint8Array(base64), 
                this.recordobj.fields.Name.value + '.xlsx'
            );
        });
    }; //generateExcel
} //CLASS END