package org.gluu.super_gluu.store.dao;

import androidx.lifecycle.LiveData;
import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Update;

import org.gluu.super_gluu.store.entity.UserTokenEntry;

import java.util.List;

@Dao
public interface UserTokenEntryDAO {

    @Query("SELECT * FROM userTokenEntry ORDER BY createdDate DESC")
    LiveData<List<UserTokenEntry>> getAll();

    @Query("SELECT * FROM userTokenEntry WHERE id = :id")
    UserTokenEntry getById(int id);

    @Query("SELECT * FROM userTokenEntry WHERE application = :application AND userName = :userName")
    UserTokenEntry getBy(String application, String userName);

    @Query("UPDATE userTokenEntry SET keyName=:newName WHERE id = :id")
    void updateKeyHandleName(String newName, int id);

    @Insert
    void insert(UserTokenEntry tokenEntry);

    @Update
    void update(UserTokenEntry tokenEntry);

    @Query("UPDATE userTokenEntry SET counter=:counter WHERE id = :id")
    void update(int counter, int id);

    @Delete
    void delete(UserTokenEntry tokenEntry);
}
