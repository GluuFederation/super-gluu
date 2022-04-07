package org.gluu.super_gluu.store.repository.userToken;

import android.app.Application;
import org.gluu.super_gluu.store.dao.UserTokenEntryDAO;
import org.gluu.super_gluu.store.database.UserTokenEntryDatabase;
import org.gluu.super_gluu.store.entity.UserTokenEntry;

public class UserTokenEntityRepository {

    private UserTokenEntryDAO mUserTokenDao;

    private String applicationName;
    private String userName;

    public UserTokenEntityRepository(Application application, String applicationName, String userName) {
        this.applicationName = applicationName;
        this.userName = userName;

        UserTokenEntryDatabase db = UserTokenEntryDatabase.getInstance(application);
        mUserTokenDao = db.userTokenEntryDAO();
    }

    public UserTokenEntry getUserTokenEntity() {
        return mUserTokenDao.getBy(applicationName, userName);
    }

    public void delete() {
        mUserTokenDao.delete(getUserTokenEntity());
    }
}
