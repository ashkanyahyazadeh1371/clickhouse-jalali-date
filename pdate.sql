
CREATE OR REPLACE FUNCTION pdate_gdm AS (i) -> multiIf(
    i=0,31, i=1,28, i=2,31, i=3,30, i=4,31,  i=5,31,
    i=6,30, i=7,31, i=8,31, i=9,30, i=10,31, 30
);

CREATE OR REPLACE FUNCTION pdate_jdm AS (i) -> multiIf(
    i=0,31, i=1,31, i=2,31, i=3,31, i=4,31,  i=5,31,
    i=6,30, i=7,30, i=8,30, i=9,30, i=10,29, 29
);

CREATE OR REPLACE FUNCTION pdate_gdn AS (gdate) ->
    365 * (toYear(gdate) - 1600)
    + intDiv(toYear(gdate) - 1600 + 3,   4)
    - intDiv(toYear(gdate) - 1600 + 99,  100)
    + intDiv(toYear(gdate) - 1600 + 399, 400)
    + pdate_gdm(0)  * ((toMonth(gdate) - 1) > 0)
    + pdate_gdm(1)  * ((toMonth(gdate) - 1) > 1)
    + pdate_gdm(2)  * ((toMonth(gdate) - 1) > 2)
    + pdate_gdm(3)  * ((toMonth(gdate) - 1) > 3)
    + pdate_gdm(4)  * ((toMonth(gdate) - 1) > 4)
    + pdate_gdm(5)  * ((toMonth(gdate) - 1) > 5)
    + pdate_gdm(6)  * ((toMonth(gdate) - 1) > 6)
    + pdate_gdm(7)  * ((toMonth(gdate) - 1) > 7)
    + pdate_gdm(8)  * ((toMonth(gdate) - 1) > 8)
    + pdate_gdm(9)  * ((toMonth(gdate) - 1) > 9)
    + pdate_gdm(10) * ((toMonth(gdate) - 1) > 10)
    + if(
        (toMonth(gdate) - 1) > 1
        AND (
            ((toYear(gdate) - 1600) % 4 = 0 AND (toYear(gdate) - 1600) % 100 != 0)
            OR (toYear(gdate) - 1600) % 400 = 0
        ), 1, 0)
    + (toDayOfMonth(gdate) - 1);

CREATE OR REPLACE FUNCTION pdate_jy AS (gdn) ->
    if(
        (gdn % 12053) % 1461 >= 366,
        979 + 33 * intDiv(gdn, 12053)
            + 4 * intDiv((gdn % 12053), 1461)
            + intDiv(((gdn % 12053) % 1461) - 1, 365),
        979 + 33 * intDiv(gdn, 12053)
            + 4 * intDiv((gdn % 12053), 1461)
    );

CREATE OR REPLACE FUNCTION pdate_j3 AS (gdn) ->
    if(
        (gdn % 12053) % 1461 >= 366,
        (((gdn % 12053) % 1461) - 1) % 365,
        (gdn % 12053) % 1461
    );

CREATE OR REPLACE FUNCTION pdate_jm AS (j3) ->
    multiIf(
        j3 < 31,  1,
        j3 < 62,  2,
        j3 < 93,  3,
        j3 < 124, 4,
        j3 < 155, 5,
        j3 < 186, 6,
        j3 < 216, 7,
        j3 < 246, 8,
        j3 < 276, 9,
        j3 < 306, 10,
        j3 < 335, 11,
        12
    );

CREATE OR REPLACE FUNCTION pdate_jd AS (j3) ->
    multiIf(
        j3 < 31,  j3 + 1,
        j3 < 62,  j3 - 31  + 1,
        j3 < 93,  j3 - 62  + 1,
        j3 < 124, j3 - 93  + 1,
        j3 < 155, j3 - 124 + 1,
        j3 < 186, j3 - 155 + 1,
        j3 < 216, j3 - 186 + 1,
        j3 < 246, j3 - 216 + 1,
        j3 < 276, j3 - 246 + 1,
        j3 < 306, j3 - 276 + 1,
        j3 < 335, j3 - 306 + 1,
        j3 - 335 + 1
    );

CREATE OR REPLACE FUNCTION pdate AS (gdate) ->
    concat(
        toString(pdate_jy(pdate_gdn(gdate) - 79)),
        '-',
        leftPad(toString(pdate_jm(pdate_j3(pdate_gdn(gdate) - 79))), 2, '0'),
        '-',
        leftPad(toString(pdate_jd(pdate_j3(pdate_gdn(gdate) - 79))), 2, '0')
    );

CREATE OR REPLACE FUNCTION pdate_jdn AS (jy, jm, jd) ->
    12053 * intDiv(jy - 979, 33)
    + 1461 * intDiv((jy - 979) % 33, 4)
    + ((jy - 979) % 33 % 4) * 365
    + if((jy - 979) % 33 % 4 > 0, 1, 0)
    + multiIf(
        jm = 1,  0,
        jm = 2,  31,
        jm = 3,  62,
        jm = 4,  93,
        jm = 5,  124,
        jm = 6,  155,
        jm = 7,  186,
        jm = 8,  216,
        jm = 9,  246,
        jm = 10, 276,
        jm = 11, 306,
        335          
    )
    + (jd - 1);


CREATE OR REPLACE FUNCTION gdate AS (jdate_str) ->
	addDays(
        toDate('1970-01-01'),
        pdate_jdn(
            toUInt32(splitByChar('-', jdate_str)[1]),
            toUInt32(splitByChar('-', jdate_str)[2]),
            toUInt32(splitByChar('-', jdate_str)[3])
        ) + 79 - 135140
    );
