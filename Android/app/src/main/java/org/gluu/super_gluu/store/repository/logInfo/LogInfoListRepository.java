package org.gluu.super_gluu.store.repository.logInfo;

import android.app.Application;

import androidx.lifecycle.LiveData;

import org.gluu.super_gluu.store.dao.LogInfoEntryDAO;
import org.gluu.super_gluu.store.database.UserTokenEntryDatabase;
import org.gluu.super_gluu.store.entity.LogInfoEntry;

import java.util.List;

public class LogInfoListRepository {

    private LogInfoEntryDAO mLogInfoDao;

    public LogInfoListRepository(Application application) {
        UserTokenEntryDatabase db = UserTokenEntryDatabase.getInstance(application);
        mLogInfoDao = db.logInfoEntryDAO();
    }

    public LiveData<List<LogInfoEntry>> getAllEntity() {
        return mLogInfoDao.getAll();
    }
}
