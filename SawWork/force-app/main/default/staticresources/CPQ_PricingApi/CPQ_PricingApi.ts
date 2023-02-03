//Path to Apex REST Resource
const PATH = '/services/apexrest/pricing/';
const PAC_LINK = 'https://control.akamai.com/apps/buy-akamai-ui/#/pac/product/';
//way to store this map in metadata or setting
const dependencyMap = [
    {
        dependentPLI: "M-LC-162045M-LC-162351nullMbpsCommitment + OverageMonthly",
        mainPLI: ["M-LC-162045nullnullMbpsCommitment + OverageMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-162045M-LC-162351Qty"
    },
    {
        dependentPLI: "M-LC-162045M-LC-162351nullGBCommitment + OverageMonthly",
        mainPLI: ["M-LC-162045nullnullGBQuantity based commitMonthly", "M-LC-162045nullnullGBCommitment + OverageMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-162045M-LC-162351Qty"
    },
    {
        dependentPLI: "M-LC-162044M-LC-162370nullMbpsCommitment + OverageMonthly",
        mainPLI: ["M-LC-162044nullnullMbpsCommitment + OverageMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-162044M-LC-162370Qty"
    },
    {
        dependentPLI: "M-LC-162044M-LC-162370nullGBCommitment + OverageMonthly",
        mainPLI: ["M-LC-162044nullnullGBQuantity based commitMonthly", "M-LC-162044nullnullGBCommitment + OverageMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-162044M-LC-162370Qty"
    },
    {
        dependentPLI: "M-LC-159926M-LC-159935M-LC-168897EachFlat FeeOne-Time",
        mainPLI: ["M-LC-159926M-LC-159935nullMapsCommitmentMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-159935M-LC-168897Qty"
    },
    {
        dependentPLI: "M-LC-161400M-LC-161401M-LC-168897EachFlat FeeOne-Time",
        mainPLI: ["M-LC-161400M-LC-161401nullMapsCommitmentMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-161401M-LC-168897Qty"
    },
    {
        dependentPLI: "M-LC-162617M-LC-166220nullUsersCommitmentMonthly",
        mainPLI: ["M-LC-162617nullnullUsersCommitmentMonthly"],
        comparisonField: "SBQQ__Quantity__c",
        errorCode: "M-LC-162617M-LC-166220Qty"
    }
];

// SET TO FALSE IN PRODUCTION
const DEBUG = true;

function debug(...args) {
    if (DEBUG) {
        console.log(...args);
    }
}

/**
* This method is called by the calculator before calculation begins, but after formula fields have been evaluated.
* @param {QuoteModel} quote JS representation of the quote being evaluated
* @param {QuoteLineModel[]} lines An array containing JS representations of all lines in the quote
* @param {Object} conn JSforce connection object
* @returns {Promise}
*/

export function onBeforeCalculate(quote, lines, conn) {
    debug('--- QCP: start onBeforeCalculate function ---');
    if (quote.record['CPQ_Quote_Type__c'] === 'Partner') {
        // Logging of models provided
        debug('--- QCP: entry criteria passed: is partner quote ---');
        debug('Quote Model: ');
        debug(quote);
        debug('Quote Line Models: ');
        debug(lines);

        // if no lines exist
        if (lines.length === 0) {
            debug('No quotelines, skipping call to External Pricing Service');
            debug('--- QCP: end onBeforeCalculate function ---');
            return Promise.resolve();
        }

        // Generate the request body to be sent
        //send only the standalone products / bundle products
        const productIds = getBundleProdCodes(lines);
        const productIdsMap = getBundleProdCodesMap(lines);
        // const productIds = Object.keys(productIdsMap);
        debug('productIds')
        debug(productIds);

        // duplicate check before fetching the prices
        var duplicateProdExists = hasDuplicates(productIds);
        debug('duplicateProdExists', duplicateProdExists);

        if (duplicateProdExists) {
            //update field at quote level and add validation product rule
            debug('duplicate entries exist, skipping call to External Pricing Service');
            debug('--- QCP: end onBeforeCalculate function---');
            // quote.record.CPQ_Duplicate_Products__c = true;
            quote.record.CPQ_ErrorCode__c = 'Duplicate';
            return Promise.resolve();
        }

        var prodExclusion = checkProductExclusions(lines, new Set(productIds));
        debug('prodExclusion: ', prodExclusion);
        if (prodExclusion !== 'true') {
            quote.record.CPQ_ErrorCode__c = prodExclusion + 'Exclusion';
            debug(quote.record.CPQ_ErrorCode__c);
            return Promise.resolve();
        }
        /** check for required products */
        var prodInclusion = checkProductInclusions(lines, productIds);
        if (prodInclusion !== 'true') {
            quote.record.CPQ_ErrorCode__c = prodInclusion + 'Inclusion';
            debug(quote.record.CPQ_ErrorCode__c);
            return Promise.resolve();
        }
        else {
            // const partnerTier = quote.record.CPQ_Partner_Tier__c;
            // quote.record.CPQ_Duplicate_Products__c = false; //if the checkbox was made true before, make it false again
            quote.record.CPQ_ErrorCode__c = '';
            const partnerTier = 'NA';
            const partnerAccId = quote.record.CPQ_Partner_AKAM_Account_ID__c;

            //request body for the REST Apex request
            const body = {
                currencyValue: quote.record.CurrencyIsoCode,
                customerType: 'Partner',
                partnerTier: partnerTier,
                partnerAccId: partnerAccId,
                productIds: [...new Set(productIds)],
            };

            // Construct the URL to call
            const baseUrl = conn.instanceUrl + PATH;
            // replace the SBQQ visualforce domain with Salesforce my domain
            const url = baseUrl.replace('--sbqq.visualforce', '.my.salesforce');

            debug(`URL: ${url}`);
            debug('Request Body: ');
            debug(body);

            debug('request sent to apex REST: ', new Date().toISOString());
            // Make Post Request to Salesforce Apex REST class
            // JSforce conn returns a promise
            return conn
                .requestPost(url, body)
                .then(res => {
                    // Parse the response
                    const priceResponse = JSON.parse(res);
                    debug('Response: ');
                    debug(priceResponse);
                    debug('response from apex REST: ', new Date().toISOString());
                    var responseStatus = priceResponse.productDetails[0].status;
                    debug('status: ', responseStatus);
                    // if (responseStatus !== 404) {
                    if (responseStatus !== '' && responseStatus !== undefined) {
                        debug('errored status code: ', responseStatus);
                        debug('pricing not fetched!');
                        quote.record.CPQ_PAC_pricing_error__c = true;
                    } else {
                        // const extPrices = priceResponse.listItems;
                        const extProductDetails = priceResponse.productDetails;
                        debug('check length: ', extProductDetails.length);
                        const totalPriceArray = [];
                        for (let i = 0; i < extProductDetails.length; i++) {
                            debug(extProductDetails[i].listItems.length);
                            Array.prototype.push.apply(totalPriceArray, extProductDetails[i].listItems);
                        }
                        debug('check length1: ', totalPriceArray);
                        quote.record.CPQ_PAC_pricing_error__c = false;

                        const pliMap = createPLIuniqueMap(totalPriceArray);

                        //create qlMap required for validation
                        const qlMap = processLines(lines);

                        // Price the quote lines based on response
                        priceLines(quote, qlMap, pliMap);

                    }
                    debug('--- QCP: end onBeforeCalculate function ---');
                })
                .catch(err => {
                    // catch any errors
                    debug('External Pricing Error', err);
                });
        }
    } else {
        debug('--- QCP: entry criteria failed: not a partner quote---');
        return Promise.resolve();
    }
}

/**
 * This method is used to create a map of quote line unique string and line
 * @param lines 
 * @returns A map of QLs unique string and line
 */
function processLines(lines) {
    debug('processLines start');

    const qlMap = lines.reduce((qlMap, line) => {
        let tempProdCodes = [];
        let prodCodes = [];
        if (line.parentItem != null) {
            tempProdCodes = getParentCode(line, tempProdCodes);
        } else {
            //set the rate card link
            line.record.CPQ_RateCard__c = '<a href=' + PAC_LINK + line.record.SBQQ__ProductCode__c + ' target="_blank">View</a>';
            debug('nothing happens for bundle line item');
            // return;
            return qlMap;
        }

        tempProdCodes.reverse();
        // debug('after reverse : ', tempProdCodes);
        //insert nulls - for 3 level prod ids
        for (var i = 0; i < 3; i++) {
            if (tempProdCodes[i] != null) {
                prodCodes[i] = tempProdCodes[i];
            } else {
                prodCodes.push(null);
            }
        }
        // debug('prodCodes : ', prodCodes);

        var qlData = getQLdata(prodCodes, line);

        if (!Array.isArray(qlMap[qlData])) {
            qlMap[qlData] = [];
        }
        qlMap[qlData].push(line);
        return qlMap;
    }, {});

    debug('qlMap: ', qlMap);
    return qlMap;
}

/**
 * This method is used to reprice quote lines based on an array of external prices
 * @param {QuoteModel[]} quote JS representation of the quote being evaluated
 * @param {QuoteLineModel[]} lines An array containing JS representations of all lines in the quote
 * @param {Object} qlMap 
 * @param {Object} pliMap 
 */
function priceLines(quote, qlMap, pliMap) {

    //check the inter lines dependencies like quantity. E.g. KSD and client reputation
    var linesDependency = checkLinesDependency(qlMap);
    debug('linesDependency: ', linesDependency);

    if (linesDependency !== 'true') {
        debug('dependency check fail');
        quote.record.CPQ_ErrorCode__c = linesDependency;

    } else {
        debug('dependency check success');

        //logic for each line to find the price
        fetchPrice(qlMap, pliMap);

    }

}

/**
 * This method is used to validate inter-line dependencies like on Quantity, etc
 * @param qlMap 
 * @returns whether all entries in dependencyMap stand true
 */
function checkLinesDependency(qlMap) {

    //load the map of dependency and check if the current line has an entry
    for (var key in qlMap) {

        var result = dependencyMap.find(lineEntry => { return lineEntry.dependentPLI === key });

        if (result != undefined) {

            debug(key, " found inside the dependencyMap.");

            //means we need to match the attributes with the corresponding mainPLI
            let dependencyValueLine = qlMap[key][0];

            let dependentValue = getProperty('record.' + result["comparisonField"], dependencyValueLine);
            let mainValueLine, mainValue = null;

            //get the list of mainPLIs and find which one is present in the qlMap
            for (var i = 0; i < result.mainPLI.length; i++) {
                if (qlMap.hasOwnProperty(result.mainPLI[i])) {
                    mainValueLine = qlMap[result.mainPLI[i]][0]
                    mainValue = getProperty('record.' + result["comparisonField"], mainValueLine);
                    break;
                }

            }

            debug('dependentValue: ', dependentValue, '|| mainValue: ', mainValue);

            if (mainValue != null) {
                if (getProperty('record.CPQ_Billing_Model__c', mainValueLine) == 'Fee') {

                    if (dependentValue === mainValue) {
                        debug(key, " line dependecy check passed, atttributes equal");

                    } else {
                        debug("atttributes not equal");
                        return result["errorCode"];
                    }
                } else {
                    debug('Main line billing model is not Fee, skipping the check.');

                }
            } else {
                debug('main line for ', key, ' missing in qlMap.');
                return 'dependencyCheckMainLineMissing';
            }

        }
        // else {

        //     debug(key, " not found in dependencyMap.");

        // }
    }
    return 'true';

}

/**
 * This method is used to fetch the price from external pliMap for each entry in qlMap
 * @param qlMap 
 * @param pliMap 
 */
function fetchPrice(qlMap, pliMap) {

    for (var qlData in qlMap) {

        var pliMatches = pliMap[qlData]; // get matching PLIs for the unique key

        if (pliMatches) {
            var externalPrice = pliMap[qlData][0]; //as fall back - default to first match OR if only 1 match returned, then set it as the price found

            // var line = qlMap[qlData][0];

            for (var i = 0; i < qlMap[qlData].length; i++) {
                var line = qlMap[qlData][i];

                debug('number: ', line.record.SBQQ__Number__c, ' start');
                debug('pliMatches: ', pliMatches);

                if (pliMatches.length > 1) {
                    //if more than 1 matches returned -> compare with name string
                    var bestMatchPli = pliMatches.find(value => {
                        debug('pli name: ', value.name);
                        debug('quote line name', line.record.CPQ_PAC_Line_Item_Id1__c);
                        return value.name == line.record.CPQ_PAC_Line_Item_Id1__c;
                    });
                    debug('bestMatchPli: ', bestMatchPli);

                    if (bestMatchPli) {
                        externalPrice = bestMatchPli;
                    } else {
                        // get highest price out of the matches
                        externalPrice = getMaxPriceMatch(pliMatches, line, 'wholesale');
                    }
                }

                debug('ql Data:', qlData);
                debug('price found: ', externalPrice);
                debug('quantity: ', line.record.SBQQ__Quantity__c);
                debug('CPQ_QBC_validity__c: ', line.record.CPQ_QBC_validity__c);

                // Check if there is an external price object
                // Check if the price is not null
                if (externalPrice.tiers != null) {
                    var applicableTier = getApplicableTier(externalPrice, line);

                    if (applicableTier) {
                        // populate the target price in QLs list unit price
                        // Use the Special Price field on the quote line to put the external price in

                        line.record.CPQ_Target_Price__c = applicableTier.geoRegionPricing[0].pricePoints['target'];
                        line.record.CPQ_Wholesale_Rate__c = applicableTier.geoRegionPricing[0].pricePoints['wholesale'];
                        line.record.CPQ_Overage__c = applicableTier.geoRegionPricing[0].pricePoints['wholesaleOverage'];
                        line.record.SBQQ__SpecialPriceType__c = 'Custom';
                        line.record.SBQQ__SpecialPriceDescription__c = 'Price received from external system';

                        debug('price: ', line.record.CPQ_Wholesale_Rate__c + ' -- Overage: ' + line.record.CPQ_Overage__c);
                    } else {
                        debug('no applicableTier');
                        /** LOGIC to handle if no tier matched */
                    }
                    //set the rate card link
                    // line.record.CPQ_RateCard__c = '<a href=' + PAC_LINK + prodCodes[0] + ' target="_blank">View</a>';
                    debug('number: ', line.record.SBQQ__Number__c, ' end');

                    // line.record.Last_External_Calculated_Time__c = new Date().toISOString();
                } else {
                    debug('empty tiers array');
                    // If no external price, log it on the line and set a timestamp.
                    line.record.SBQQ__SpecialPriceDescription__c = 'No price from external system';

                    // line.record.Last_External_Calculated_Time__c = new Date().toISOString();
                }
            }
        } else {
            debug('no PLI matched for: ', qlData);
            /** LOGIC to handle if no PLI matched */
        }
    }

}

/**
 * A function to take a string written in dot notation style, and use it to
 * find a nested object property inside of an object.
 *
 * Useful in a plugin or module that accepts a JSON array of objects, but
 * you want to let the user specify where to find various bits of data
 * inside of each custom object instead of forcing a standardized
 * property list.
 *
 * @param String nested A dot notation style parameter reference (ie "urls.small")
 * @param Object object (optional) The object to search
 *
 * @return the value of the property in question
 */
function getProperty(propertyName, object) {
    var parts = propertyName.split("."),
        length = parts.length,
        i,
        property = object || this;

    for (i = 0; i < length; i++) {
        property = property[parts[i]];
    }

    return property;
}

/** Get the top level bundle product codes */
function getBundleProdCodes(quoteLineModels) {
    const prodCodes = quoteLineModels.reduce((prodCodes, line) => {
        if (!line.parentItemKey) {
            prodCodes.push(line.record.SBQQ__ProductCode__c);
        }
        return prodCodes;
    }, []);

    debug('top level prodCodes', prodCodes);
    return prodCodes;
}

/** Get the top level bundle product codes map */
function getBundleProdCodesMap(quoteLineModels) {
    const prodCodesMap = quoteLineModels.reduce((prodCodesMap, line) => {
        if (!line.parentItemKey) {
            if (!Array.isArray(prodCodesMap[line.record.SBQQ__ProductCode__c])) {
                prodCodesMap[line.record.SBQQ__ProductCode__c] = [];
            }
            prodCodesMap[line.record.SBQQ__ProductCode__c].push(line.record.SBQQ__ProductFamily__c);
        }
        return prodCodesMap;
    }, {});

    debug('top level prodCodes Map', prodCodesMap);
    return prodCodesMap;
}

/** Duplicate check */
function hasDuplicates(arr) {
    return new Set(arr).size !== arr.length;
}

/** check product inclusions are valid */
function checkProductExclusions(quoteLineModels, productIds) {
    debug('checking ProductExclusions...');
    //productIds is a SET of main prod ids
    let prodExclusionMap = new Map();

    quoteLineModels.forEach((line) => {
        if (line.record.CPQ_Product_Exclusion__c) {
            var tempArray = line.record.CPQ_Product_Exclusion__c.split(';');
            debug('tempArray: ', tempArray);
            prodExclusionMap.set(line.record.SBQQ__ProductCode__c, tempArray);
        }
    });
    debug('prodExclusionMap');
    debug(prodExclusionMap);

    if (prodExclusionMap && prodExclusionMap.size > 0) {
        for (let [key, value] of prodExclusionMap.entries()) {
            for (var i = 0; i < value.length; i++) {
                var currentValue = prodExclusionMap.get(key)[i];
                if (productIds.has(currentValue)) {
                    return key + currentValue;
                }
            }
        }
    }
    return 'true';
}

/** check product inclusions are valid */
function checkProductInclusions(quoteLineModels, productIds) {
    debug('checking ProductInclusions...');

    var productIdsSet = new Set(productIds);

    let prodInclMap = new Map();

    quoteLineModels.forEach((line) => {
        if (line.record.CPQ_Product_Inclusion__c) {
            debug('entered if logic: ', line.record.CPQ_Product_Inclusion__c);
            var tempArray = line.record.CPQ_Product_Inclusion__c.split(';');
            debug('tempArray: ', tempArray);
            debug('associated prod id: ', line.record.CPQ_Associated_Product_Id__c)
            prodInclMap.set(line.record.CPQ_Associated_Product_Id__c, tempArray);
        }
    });
    debug('prodInclMap');
    debug(prodInclMap);

    var prodInclStatus = [];
    var obj = {};
    if (prodInclMap && prodInclMap.size > 0) {
        for (let [key, value] of prodInclMap.entries()) {
            obj['prod'] = key;
            obj['status'] = false;
            for (var i = 0; i < value.length; i++) {
                if (productIdsSet.has(prodInclMap.get(key)[i])) {
                    obj['status'] = true;
                    break;
                }
            }
            prodInclStatus.push(obj);
        }
        debug('prodInclStatus');
        debug(prodInclStatus);

        var falseProd = prodInclStatus.find(prod => {
            return prod.status == false;
        });
        debug('falseProd');
        debug(falseProd);

        if (falseProd) {
            return falseProd.prod;
        } else {
            return 'true';
        }
    } else {
        return 'true';
    }

}

/**
* Builds a map of a PLIs using the unique key
* @param priceArray
* @return Object
*/
function createPLIuniqueMap(priceArray) {
    debug('typeof priceArray: ', typeof priceArray);
    const pliMap = priceArray.reduce((pliMap, pli) => {

        let uniqueString =
            pli.productId + pli.associatedProdId + pli.secLvlAssociatedProdId + pli.uom + pli.pricingModel + pli.billingFrequency;
        // debug('uniqueString', uniqueString);

        if (!Array.isArray(pliMap[uniqueString])) {
            pliMap[uniqueString] = [];
        }

        pliMap[uniqueString].push(pli);
        return pliMap;
    }, {});

    debug('pliMap', pliMap);
    return pliMap;
}

/** recursively get parent prod codes in an array */
function getParentCode(quoteLine, result) {
    if (quoteLine.parentItem) {
        // debug(quoteLine.parentItem.ProductCode__c);
        result.push(quoteLine.parentItem.ProductCode__c);
        getParentCode(quoteLine.parentItem, result);
    }
    // debug('result: ', result);
    return result;
}

function getQLdata(prodCodes, line) {
    var qlData = '';

    let qlAssociatedProdId = line.record.CPQ_Associated_Product_Id__c;
    if (prodCodes[0] == line.record.CPQ_Associated_Product_Id__c) {
        qlAssociatedProdId = null;
    }

    //if the line belongs to bundled add-on product like NetStorage
    if (prodCodes[1] != null && prodCodes[2] != null) {
        qlData =
            prodCodes[0] +
            prodCodes[1] +
            prodCodes[2] +
            line.record.CPQ_Measurement__c +
            line.record.CPQ_Charge_Type__c +
            line.record.CPQ_Billing_Frequency__c;
    } else if (prodCodes[1] != null && prodCodes[2] == null && prodCodes[1] != qlAssociatedProdId) {
        qlData =
            prodCodes[0] +
            prodCodes[1] +
            qlAssociatedProdId +
            line.record.CPQ_Measurement__c +
            line.record.CPQ_Charge_Type__c +
            line.record.CPQ_Billing_Frequency__c;
    } else if (prodCodes[1] != null) {
        qlData =
            prodCodes[0] +
            prodCodes[1] +
            prodCodes[2] +
            line.record.CPQ_Measurement__c +
            line.record.CPQ_Charge_Type__c +
            line.record.CPQ_Billing_Frequency__c;
    } else {
        qlData =
            prodCodes[0] +
            qlAssociatedProdId +
            prodCodes[2] +
            line.record.CPQ_Measurement__c +
            line.record.CPQ_Charge_Type__c +
            line.record.CPQ_Billing_Frequency__c;
    }
    // debug('qlData: ', qlData);
    return qlData;
}

/**
* Get the tier range in which the line quantity falls
*/
function getApplicableTier(externalPrice, line) {
    var tierIndex = null;
    var applicableTier = externalPrice.tiers.find((tier, index) => {
        if (tier.tierLow['value'] == tier.tierHigh['value']) {
            //low and high value is same in case of QBC, calculate the applicable tier
            tierIndex = getApplicableTierIndex(externalPrice.tiers, line.record.SBQQ__Quantity__c);
            debug(index + ' -- ' + tierIndex);
            return index === tierIndex;
            // return tier.tierHigh['value'] >= line.record.SBQQ__Quantity__c;
        } else if (tier.tierLow['value'] < tier.tierHigh['value']) {
            return tier.tierLow['value'] <= line.record.SBQQ__Quantity__c && tier.tierHigh['value'] >= line.record.SBQQ__Quantity__c;
        } else if ((tier.tierLow['value'] == 1 || tier.tierLow['value'] == 0 || tier.tierLow['value'] != null) && tier.tierHigh['value'] == null) {
            //example mPulse - Managed Integration - Additional domain - One time fee
            return tier.tierLow['value'] <= line.record.SBQQ__Quantity__c;
        }
    });

    if (!applicableTier) {
        debug('quantity reached custom price tier. defaulting to last but one tier.');
        //pick last but one tier
        applicableTier = externalPrice.tiers[externalPrice.tiers.length - 2];
    }

    /** if the PLI is QBC and estimated wholesale rate is to be applied
    * update the wholesale with estimated wholesale rate
    * upadte the target price with [applicable_tier + 1]'s target price
    * wholesaleRateEstimated is a custom pricepoint added in script for calculation purposes ONLY
    */
    if (applicableTier.geoRegionPricing[0].pricePoints['wholesaleRateEstimated']) {
        applicableTier.geoRegionPricing[0].pricePoints['wholesale'] = applicableTier.geoRegionPricing[0].pricePoints['wholesaleRateEstimated'];
        applicableTier.geoRegionPricing[0].pricePoints['target'] = externalPrice.tiers[tierIndex + 1].geoRegionPricing[0].pricePoints['target'];
    }
    //for included units the overage rate will be in the next tier
    if (line.record.CPQ_Charge_Type__c === 'Included Units' && applicableTier.geoRegionPricing[0].pricePoints['wholesaleOverage'] == null && externalPrice.tiers[tierIndex + 1] !== undefined) {
        applicableTier.geoRegionPricing[0].pricePoints['wholesaleOverage'] = externalPrice.tiers[tierIndex + 1].geoRegionPricing[0].pricePoints['wholesaleOverage'];
    }
    debug('applicableTier');
    debug(applicableTier);
    return applicableTier;
}

/**
* This method identifies the tier to considered for QBC
* LOGIC: lowerTier_WholesaleRate + ((lowerTier - qty) * lowerTier_WholesaleOverage) || higherTier_WholesaleRate (which ever is less)
* @param tiers array of tiers for PLI selected
* @param line current quote line
*/
function getApplicableTierIndex(tiers, quantity) {
    //get higher tier index
    var highTierIndex = tiers.findIndex(tier => {
        return tier.tierHigh['value'] >= quantity;
    });

    debug('highTierIndex ', highTierIndex);

    if (highTierIndex !== 0 && highTierIndex > 0) {
        //if qty is not an exact range value
        if (quantity !== tiers[highTierIndex].tierHigh['value']) {
            var lowerTier = tiers[highTierIndex - 1];
            var higherTier = tiers[highTierIndex];
            var higherTierWholesaleRate = higherTier.geoRegionPricing[0].pricePoints['wholesale'];

            var difference = quantity - lowerTier.tierLow['value'];

            var estimatedWholesaleRate = null;
            if (lowerTier.geoRegionPricing[0].pricePoints['wholesaleOverage']) {
                estimatedWholesaleRate =
                    lowerTier.geoRegionPricing[0].pricePoints['wholesale'] +
                    difference * lowerTier.geoRegionPricing[0].pricePoints['wholesaleOverage'];
            }
            debug('estimatedWholesaleRate ', estimatedWholesaleRate);
            debug('higher tier wholeslaeRate : ', higherTierWholesaleRate);
            //check estimated is less than higher than
            if (estimatedWholesaleRate !== null && estimatedWholesaleRate < higherTierWholesaleRate) {
                debug('lower');
                //wholesaleRateEstimated is a custom pricepoint added in script for calculation purposes ONLY
                lowerTier.geoRegionPricing[0].pricePoints['wholesaleRateEstimated'] = estimatedWholesaleRate;
                return highTierIndex - 1;
            } else {
                debug('higher');
                return highTierIndex;
            }
        } else {
            //if qty is an exact range value
            debug('higher: exact range value');
            return highTierIndex;
        }
    } else {
        return 0;
    }
}

/**
* Get the maximum value from a list of values.
* If a field is null/undefined, it will be ignored in calculation
*/
function getMaxPriceMatch(matchList, line, pricepoint) {
    const maxPriceMatch = matchList.reduce((maxPriceMatch, matchItem) => {
        var applicableTier = getApplicableTier(matchItem, line);
        var tierPrice = applicableTier.geoRegionPricing[0].pricePoints[pricepoint];
        debug('tierPrice', tierPrice);
        // if (tierPrice) {
        if (!maxPriceMatch.maxPrice || tierPrice > maxPriceMatch.maxPrice) {
            maxPriceMatch.maxPrice = tierPrice;
            maxPriceMatch.maxPriceMatchPLI = matchItem;
        }
        // }
        return maxPriceMatch;
    }, {});
    debug('maxPriceMatch: ', maxPriceMatch);
    return maxPriceMatch.maxPriceMatchPLI;
}

export function isFieldEditableForObject(fieldName, line, conn, objectName) {

    //Quantity field should be editable for Segmented products [CPQ-575]
    if (objectName === 'QuoteLine__c' && fieldName === 'SBQQ__Quantity__c') {
        if (line.CPQ_QuoteType__c === 'Partner' && line.SBQQ__SegmentIndex__c === null) { //lines which are not period commits
            return false;
        }
    }
    if (
        objectName === 'QuoteLine__c' &&
        (fieldName === 'CPQ_Overage__c' ||
            fieldName === 'SBQQ__SpecialPrice__c' ||
            fieldName === 'CPQ_Wholesale_Rate__c' ||
            fieldName === 'CPQ_Measurement__c' ||
            fieldName === 'CPQ_Target_Price__c' ||
            fieldName === 'CPQ_Billing_Frequency__c' ||
            fieldName === 'CPQ_Charge_Type__c' ||
            fieldName === 'SBQQ__AdditionalDiscount__c'
        )
    ) {
        if (line.CPQ_QuoteType__c === 'Partner') { //below fields should be non-editable only in case of Partners [CPQ-575]
            return false;
        }
    }
}

export function isFieldVisible(fieldName, line) {
    if (fieldName === 'CPQ_Revenue_Commitment__c') {
        if (line.CPQ_Billing_Model__c === 'Usage Commitment') {
            return true;
        } else {
            return false;
        }
    }
    if (fieldName === 'CPQ_Monthly_Fee__c') {
        if (line.CPQ_Billing_Model__c === 'Straight Line Commitment') {
            return true;
        } else {
            return false;
        }
    }
}