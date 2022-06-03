package org.gluu.super_gluu.store.entity;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.PrimaryKey;

import org.gluu.super_gluu.app.LogState;
import org.gluu.super_gluu.app.model.LogInfo;

import java.util.Date;
import java.util.Random;

@Entity(tableName = "logInfoEntry")
public class LogInfoEntry {

    @PrimaryKey(autoGenerate = true)
    private int id;

    @ColumnInfo(name = "locationIP")
    private String locationIP;

    @ColumnInfo(name = "locationAddress")
    private String locationAddress;

    @ColumnInfo(name = "message")
    private String message;

    @ColumnInfo(name = "logState")
    private LogState logState;

    @ColumnInfo(name = "method")
    private String method;

    @ColumnInfo(name = "issuer")
    private String issuer;

    @ColumnInfo(name = "userName")
    private String userName;

    @ColumnInfo(name = "createdDate")
    private Date createdDate;

    public LogInfoEntry(LogInfo logInfo) {
        this.id = new Random().nextInt();
        this.locationIP = logInfo.getLocationIP();
        this.locationAddress = logInfo.getLocationAddress();
        this.message = logInfo.getMessage();
        this.logState = logInfo.getLogState();
        this.method = logInfo.getMethod();
        this.issuer = logInfo.getIssuer();
        this.userName = logInfo.getUserName();
        this.createdDate = logInfo.getDate();
    }

    public LogInfoEntry(int id, String locationIP, String locationAddress, String message, LogState logState, String method, String issuer, String userName, Date createdDate) {
        this.id = id;
        this.locationIP = locationIP;
        this.locationAddress = locationAddress;
        this.message = message;
        this.logState = logState;
        this.method = method;
        this.issuer = issuer;
        this.userName = userName;
        this.createdDate = createdDate;
    }

    public int getId() {
        return id;
    }

    public String getLocationIP() {
        return locationIP;
    }

    public String getLocationAddress() {
        return locationAddress;
    }

    public String getMessage() {
        return message;
    }

    public LogState getLogState() {
        return logState;
    }

    public String getMethod() {
        return method;
    }

    public String getIssuer() {
        return issuer;
    }

    public String getUserName() {
        return userName;
    }

    public Date getCreatedDate() {
        return createdDate;
    }
}
