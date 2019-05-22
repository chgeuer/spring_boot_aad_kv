/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See LICENSE in the project root for
 * license information.
 */

package com.sap.concur.demo.aaddemo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class PetRepository {
    private static final String SQL_FIND_BY_ID = "SELECT * FROM PET WHERE ID = :id";
    private static final String SQL_FIND_ALL = "SELECT * FROM PET";
    private static final String SQL_INSERT = "INSERT INTO PET (NAME, SPECIES) values(:name, :species)";
    private static final String SQL_DELETE_BY_ID = "DELETE FROM PET WHERE ID = :id";

    private static final BeanPropertyRowMapper<Pet> ROW_MAPPER = new BeanPropertyRowMapper<>(Pet.class);

    @Autowired
    NamedParameterJdbcTemplate jdbcTemplate;

    public Pet findById(Integer id) {
        try {
            final SqlParameterSource paramSource = new MapSqlParameterSource("id", id);
            return jdbcTemplate.queryForObject(SQL_FIND_BY_ID, paramSource, ROW_MAPPER);
        }
        catch (EmptyResultDataAccessException ex) {
            return null;
        }
    }

    public Iterable<Pet> findAll() {
        return jdbcTemplate.query(SQL_FIND_ALL, ROW_MAPPER);
    }

    public int save(Pet pet) {
        final SqlParameterSource paramSource = new MapSqlParameterSource()
                .addValue("name", pet.getName())
                .addValue("species", pet.getSpecies());

        return jdbcTemplate.update(SQL_INSERT, paramSource);
    }

    public void deleteById(Integer id) {
        final SqlParameterSource paramSource = new MapSqlParameterSource("id", id);
        jdbcTemplate.update(SQL_DELETE_BY_ID, paramSource);
    }
}