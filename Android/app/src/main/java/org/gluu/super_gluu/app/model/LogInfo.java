package org.gluu.super_gluu.app.model;

import org.gluu.super_gluu.app.LogState;
import org.gluu.super_gluu.app.settings.Settings;
import org.gluu.super_gluu.store.entity.LogInfoEntry;
import org.gluu.super_gluu.u2f.v2.entry.Entry;

/**
 * Created by nazaryavornytskyy on 4/19/16.
 */
public class LogInfo extends Entry {

    private String locationIP;
    private String locationAddress;
    private String message;
    private LogState logState;
    private String method;

    public LogInfo() {
    }

    public LogInfo(String issuer, String userName, String locationIP, String locationAddress, String created, LogState logState, String method) {
        setIssuer(issuer);
        setUserName(userName);
        setCreatedDate(created);
        this.locationIP = locationIP;
        this.locationAddress = locationAddress;
        this.logState = logState;
        this.method = method;
    }

    public LogInfo(LogInfoEntry logInfoEntry) {
        setIssuer(logInfoEntry.getIssuer());
        setUserName(logInfoEntry.getUserName());
        setCreatedDate(Settings.isoDateTimeFormat.format(logInfoEntry.getCreatedDate()));
        this.locationIP = logInfoEntry.getLocationIP();
        this.locationAddress = logInfoEntry.getLocationAddress();
        this.logState = logInfoEntry.getLogState();
        this.message = logInfoEntry.getMessage();
        this.method = logInfoEntry.getMethod();
    }

    public String getLocationIP() {
        return locationIP;
    }

    public void setLocationIP(String locationIP) {
        this.locationIP = locationIP;
    }

    public String getLocationAddress() {
        return locationAddress;
    }

    public void setLocationAddress(String locationAddress) {
        this.locationAddress = locationAddress;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LogState getLogState() {
        return logState;
    }

    public void setLogState(LogState logState) {
        this.logState = logState;
    }

    public String getMethod() {
        return method;
    }

    public void setMethod(String method) {
        this.method = method;
    }

}
