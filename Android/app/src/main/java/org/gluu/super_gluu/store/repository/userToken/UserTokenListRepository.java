package org.gluu.super_gluu.store.repository.userToken;

import android.app.Application;

import androidx.lifecycle.LiveData;

import org.gluu.super_gluu.store.dao.UserTokenEntryDAO;
import org.gluu.super_gluu.store.database.UserTokenEntryDatabase;
import org.gluu.super_gluu.store.entity.UserTokenEntry;

import java.util.List;

public class UserTokenListRepository {

    private UserTokenEntryDAO mUserTokenDao;

    public UserTokenListRepository(Application application) {
        UserTokenEntryDatabase db = UserTokenEntryDatabase.getInstance(application);
        mUserTokenDao = db.userTokenEntryDAO();
    }

    public LiveData<List<UserTokenEntry>> getAllEntity() {
        return mUserTokenDao.getAll();
    }
}
