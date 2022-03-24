package org.gluu.super_gluu.u2f.v2.entry;

import org.gluu.super_gluu.app.settings.Settings;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Created by nazaryavornytskyy on 4/26/16.
 */
public class Entry {

    private String issuer;
    private String userName;
    private String createdDate;

    public String getIssuer() {
        return issuer;
    }

    public void setIssuer(String issuer) {
        this.issuer = issuer;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getCreatedDate() {
        return createdDate;
    }

    public Date getDate() {
        try {
            return Settings.isoDateTimeFormat.parse(createdDate);
        } catch (ParseException e) {
            e.printStackTrace();
            return new Date();
        }
    }

    public void setCreatedDate(String createdDate) {
        this.createdDate = createdDate;
    }
}
