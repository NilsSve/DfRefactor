/*
Name:
    df.sys.json
Type:
    Library (static object)
Revisions:
    2011/08/02  Refactored to df.sys.json. (HW, DAW)
    2009/06/02  Created the initial version. (HW, DAE)
*/


/*
Library that contains the functionality to serialize and parse JSON strings to 
JavaScript objects. Functions and properties starting with a double underscore 
are skipped. If the browser supports native JSON.stringify and JSON.parse 
methods these are used (Like IE 8+ and FireFox 3.1+). For parsing the JSON the 
JSON.parse method is used. Dates are serialized into strings and parsed as 
string.
*/
export const json = {

    /*
    Deserializes a JSON string into a object structure. It uses the native 
    JSON.parse function if it is available. Otherwise it will perform a few checks 
    (to make sure the string is save for eval) and then use eval.
    
    @param  sString String with JSON.
    @return Object structure.
    */
    parse(sString) {
        if (typeof JSON === "object" && typeof JSON.parse === "function") {
            return JSON.parse(sString);
        }

        throw new SyntaxError('This browser does not support JSON');
    },

    /*
    Serializes JavaScript object structure into a JSON string. It uses the native 
    JSON.stringify function if it is available. Note that properties starting with 
    double underscores are skipped.
    
    @param  oObject Reference to the object to be serialized.
    @return String with JSON.
    */
    stringify(oObject) {
        // If native support is available we will use it
        // FIX: except for Internet Explorer 8 which has a bug serializing "" to "null" if the value comes from the value property of an input DOM element
        if (typeof JSON === "object" && typeof JSON.stringify === "function") {
            // Call native JSON stringify function 
            // replacer function is given to make sure properties with "__" are skipped
            return JSON.stringify(oObject, function (sKey, sValue) {
                return (typeof sKey === "string" && sKey.substr(0, 2) === "__" ? undefined : sValue);
            });
        }
        
        throw new SyntaxError('This browser does not support JSON');
    }

};

