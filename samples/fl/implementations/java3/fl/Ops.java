//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, vJAXB 2.1.3 in JDK 1.6 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2008.06.16 at 09:46:32 PM PDT 
//


package fl;

import javax.xml.bind.annotation.XmlEnum;
import javax.xml.bind.annotation.XmlEnumValue;
import javax.xml.bind.annotation.XmlType;


/**
 * <p>Java class for Ops.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * <p>
 * <pre>
 * &lt;simpleType name="Ops">
 *   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}token">
 *     &lt;enumeration value="Equal"/>
 *     &lt;enumeration value="Plus"/>
 *     &lt;enumeration value="Minus"/>
 *   &lt;/restriction>
 * &lt;/simpleType>
 * </pre>
 * 
 */
@XmlType(name = "Ops")
@XmlEnum
public enum Ops {

    @XmlEnumValue("Equal")
    EQUAL("Equal"),
    @XmlEnumValue("Plus")
    PLUS("Plus"),
    @XmlEnumValue("Minus")
    MINUS("Minus");
    private final String value;

    Ops(String v) {
        value = v;
    }

    public String value() {
        return value;
    }

    public static Ops fromValue(String v) {
        for (Ops c: Ops.values()) {
            if (c.value.equals(v)) {
                return c;
            }
        }
        throw new IllegalArgumentException(v);
    }

}
