package org.gluu.super_gluu.store.dao;

import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Update;

import org.gluu.super_gluu.store.entity.UserTokenEntry;

import java.util.List;

@Dao
public interface UserTokenEntryDAO {

    @Query("SELECT * FROM userTokenEntry")
    List<UserTokenEntry> getAll();

    @Query("SELECT * FROM userTokenEntry WHERE id = :id")
    UserTokenEntry getById(long id);

    @Query("SELECT * FROM userTokenEntry WHERE application = :application AND userName = :userName")
    UserTokenEntry getBy(String application, String userName);

    @Insert
    void insert(UserTokenEntry tokenEntry);

    @Update
    void update(UserTokenEntry tokenEntry);

    @Delete
    void delete(UserTokenEntry tokenEntry);
}
