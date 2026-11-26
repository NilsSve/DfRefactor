/*
Namespace:
    df.sys.vt

This namespace contains the functionality needed to work with valuetrees. It can serialize and 
deserialize the valuetrees from and to usable objects. It is capable of generating a serialize and 
deserialize function based on a provided format as optimization. For the generation and live 
deserialization it is required to provide the format which can be done by passing an example object
 structure where actual values are replaced with integer constants representing the type. An example 
 is given below.
@code
{ aArray : [ { sMember : df.tString, iMember : df.tInt } ], bMember : df.tBool }
@code

Revision:
    2013/11/02  (HW, DAW) 
        Initial version.
*/
export const vt = {

    /* 
    Generates a deserialization function based on the provided format definition. The function will know 
    the format allowing it parse the valuetree faster. The resulting function has a single parameter 
    (the value tree) and returns the object structure.
    
    @code
    myParser = df.sys.vt.generateDeserializer({ aArray : [ { sMember : df.tString, iMember : df.tInt } ], bMember : df.tBool });
    oObj = myParser(tVT);
    @code
    
    @param  tDef    Format definition.
    @return Function that can parse a value tree into an object structure with the provided format.
    @deprecated
    */
    generateDeserializer(tDef) {
        console.warn("df.sys.vt.generateDeserializer is deprecated and will be removed in the future. Use df.sys.vt.deserialize instead.");

        //  Since 'new Function' is considered unsave (unsafe-eval) we no redirect to the 'slower' runtime version
        return (tVT) =>{
            return this.deserialize(tVT, tDef);
        };
    },

    /*
    Generates a serialization function based on the provided format definition. The function will know 
    the format allowing it to generate the valuetree faster than when using object reflection.
    
    @code
    serializeVT = df.sys.vt.generateSerializer({ aArray : [ { sMember : df.tString, iMember : df.tInt } ], bMember : df.tBool });
    tVT = serializeVT(tStruct);
    @code
    
    @param  tDef    Definition object.
    @return Function that can generate a value tree for objects of this format.
    @deprecated
    */
    generateSerializer(tDef) {
        console.warn("df.sys.vt.generateSerializer is deprecated and will be removed in the future. Use df.sys.vt.serialize instead.");

        //  Since 'new Function' is considered unsave (unsafe-eval) we no redirect to the 'slower' runtime version
        return (tStruct) => {
            return this.serialize(tStruct, tDef);
        };
    },

    /*
    Deserializes a valuetree into usable objects based on the provided format.
    
    @param  tVT     The value tree.
    @param  tDef    Definition object.
    @return Objects based on the definition containing the data from the value tree.
    */
    deserialize(tVT, tDef) {

        function parseObj(tVT, tDef) {
            var sM, i = 0, oRes = {};

            for (sM in tDef) {
                if (tDef.hasOwnProperty(sM)) {
                    oRes[sM] = switchType(tVT.c[i], tDef[sM]);

                    i++;
                }
            }

            return oRes;
        }

        function parseArray(tVT, tDef) {
            var i, aRes = [];

            for (i = 0; i < tVT.c.length; i++) {
                aRes.push(switchType(tVT.c[i], tDef[0]));
            }

            return aRes;
        }

        function parseEndNode(tVT, tDef) {
            switch (tDef) {
                case df.tBool:
                    return df.toBool(tVT.v);
                case df.tInt:
                    return df.toInt(tVT.v);
                case df.tNumber:
                    return df.toNumber(tVT.v);
                case df.tDate:
                    return df.toDate(tVT.v);
                default:
                    return tVT.v;
            }
        }

        function switchType(tVT, tDef) {
            if (typeof (tDef) === "number") {
                return parseEndNode(tVT, tDef);
            }
            if (tDef instanceof Array) {
                return parseArray(tVT, tDef);
            }
            return parseObj(tVT, tDef);
        }

        try {
            return switchType(tVT, tDef);
        } catch (oErr) {
            throw new df.Error(999, "Unable to deserialize valuetree, invalid data format!\\n\\r\\n\\rMSG: {{0}}", this, [oErr.message]);
        }
    },

    /* 
    Serializes the passed objects into a value tree. It will serialize all the available properties of 
    the objects themselves (so not of the prototype).
    
    @param  tStruct Data objects to serialize.
    @return Valuetree with the data.
    */
    serialize(tStruct) {
        function parseObj(oObj) {
            var sM, oRes = { v: "", c: [] };

            for (sM in oObj) {
                if (oObj.hasOwnProperty(sM)) {
                    oRes.c.push(switchType(oObj[sM]));
                }
            }

            return oRes;
        }

        function parseArray(aArray) {
            var i, oRes = { v: "", c: [] };

            for (i = 0; i < aArray.length; i++) {
                oRes.c.push(switchType(aArray[i]));
            }

            return oRes;
        }

        function parseEndNode(oObj) {
            if (typeof oObj === "boolean") {
                return { v: df.fromBool(oObj), c: [] };
            }
            if (oObj instanceof Date) {
                return { v: df.fromDate(oObj), c: [] };
            }
            return { v: oObj.toString(), c: [] };
        }

        function switchType(tStruct) {
            if (typeof (tStruct) === "object") {
                if (tStruct instanceof Array) {
                    return parseArray(tStruct);
                }
                if (tStruct instanceof Date) {
                    return parseEndNode(tStruct);
                }
                return parseObj(tStruct);
            }
            return parseEndNode(tStruct);

        }

        try {
            return switchType(tStruct);
        } catch (oErr) {
            throw new df.Error(999, "Unable to serialize valuetree, invalid data format!\\n\\r\\n\\rMSG: {{0}}", this, [oErr.message]);
        }
    }

};