SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Last_Info_Fighter] (
   @FileNo BIGINT
)RETURNS TABLE 
AS
RETURN
(
SELECT     dbo.Fighter.FILE_NO, dbo.Fighter.DEBT_DNRM, dbo.Fighter.BUFE_DEBT_DNTM, dbo.Fighter.REGN_PRVN_CODE, dbo.Fighter.REGN_CODE, dbo.Fighter.FGPB_RWNO_DNRM, dbo.Fighter.MBSP_RWNO_DNRM, dbo.Fighter.CAMP_RWNO_DNRM, dbo.Fighter.TEST_RWNO_DNRM, dbo.Fighter.CLCL_RWNO_DNRM, 
           dbo.Fighter.HERT_RWNO_DNRM, dbo.Fighter.PSFN_RWNO_DNRM, dbo.Fighter.CONF_DATE, dbo.Fighter.RQST_RQID, dbo.Fighter.NAME_DNRM, dbo.Fighter.FATH_NAME_DNRM, 
           dbo.Fighter.BRTH_DATE_DNRM, dbo.Fighter.CELL_PHON_DNRM, dbo.Fighter.TELL_PHON_DNRM, dbo.Fighter.INSR_NUMB_DNRM, dbo.Fighter.INSR_DATE_DNRM, 
           dbo.Fighter.TEST_DATE_DNRM, dbo.Fighter.CAMP_DATE_DNRM, dbo.Fighter_Public.NATL_CODE, dbo.Fighter_Public.GLOB_CODE, dbo.Fighter_Public.POST_ADRS, dbo.Fighter_Public.FRST_NAME, dbo.Fighter_Public.LAST_NAME,dbo.Fighter_Public.TYPE, dbo.Fighter_Public.CBMT_CODE,
           dbo.Fighter_Public.EMAL_ADRS, dbo.Diseases_Type.DISE_DESC, dbo.Club.NAME AS CLUB_NAME, ISNULL(dbo.Club.CODE, 0) AS CLUB_CODE, dbo.D$FGTP.DOMN_DESC AS TYPE_DESC, dbo.D$DEGR.DOMN_DESC AS COCH_DEGR, dbo.Fighter_Public.COCH_FILE_NO, dbo.Fighter.ACTV_TAG_DNRM, dbo.Fighter.MOST_DEBT_CLNG_DNRM,
           D$DEGR_1.DOMN_DESC AS GUGD_DEGR, dbo.D$SXTP.DOMN_DESC AS SEX_TYPE, dbo.D$FGST.DOMN_DESC AS FIGH_STAT, dbo.Method.MTOD_DESC, dbo.Category_Belt.CTGY_DESC,
           dbo.D$ACTG.DOMN_DESC AS ACTV_TAG, dbo.Region.NAME AS REGN_NAME, dbo.Province.NAME AS PRVN_NAME, dbo.D$BLOD.DOMN_DESC AS BLOD_GROP, dbo.Request_Type.RQTP_DESC, dbo.Fighter.FNGR_PRNT_DNRM,
           dbo.Fighter_Public.SUNT_BUNT_DEPT_ORGN_CODE, dbo.Fighter_Public.SUNT_BUNT_DEPT_CODE, dbo.Fighter_Public.SUNT_BUNT_CODE, dbo.Fighter_Public.SUNT_CODE,
           dbo.Organ.ORGN_DESC, dbo.Department.DEPT_DESC, dbo.Base_Unit.BUNT_DESC, dbo.Sub_Unit.SUNT_DESC,
           dbo.Member_Ship.STRT_DATE,dbo.Member_Ship.END_DATE, dbo.Member_Ship.NUMB_OF_MONT_DNRM, dbo.Member_Ship.NUMB_OF_DAYS_DNRM, ISNULL(dbo.Member_Ship.NUMB_MONT_OFER , 0) NUMB_MONT_OFER,
           dbo.Member_Ship.NUMB_OF_ATTN_MONT, dbo.Member_Ship.NUMB_OF_ATTN_WEEK, dbo.Member_Ship.SUM_ATTN_MONT_DNRM, dbo.Member_Ship.SUM_ATTN_WEEK_DNRM           
FROM         dbo.Fighter INNER JOIN
             dbo.Fighter_Public ON dbo.Fighter.FILE_NO = dbo.Fighter_Public.FIGH_FILE_NO AND dbo.Fighter.FGPB_RWNO_DNRM = dbo.Fighter_Public.RWNO LEFT OUTER JOIN
             dbo.Club ON dbo.Fighter_Public.CLUB_CODE = dbo.Club.CODE LEFT OUTER JOIN
             dbo.Member_Ship ON dbo.Fighter.FILE_NO = dbo.Member_Ship.FIGH_FILE_NO AND dbo.Fighter.MBSP_RWNO_DNRM = dbo.Member_Ship.RWNO AND dbo.Member_Ship.RECT_CODE = '004' LEFT OUTER JOIN 
             dbo.Diseases_Type ON dbo.Fighter_Public.DISE_CODE = dbo.Diseases_Type.CODE LEFT OUTER JOIN
             dbo.D$FGTP ON dbo.Fighter_Public.TYPE = dbo.D$FGTP.VALU LEFT OUTER JOIN
             dbo.D$SXTP ON dbo.Fighter_Public.SEX_TYPE = dbo.D$SXTP.VALU LEFT OUTER JOIN
             dbo.D$FGST ON dbo.Fighter.FIGH_STAT = dbo.D$FGST.VALU LEFT OUTER JOIN
             dbo.Method ON dbo.Fighter.MTOD_CODE_DNRM = dbo.Method.CODE LEFT OUTER JOIN
             dbo.Category_Belt ON dbo.Method.CODE = dbo.Category_Belt.MTOD_CODE AND dbo.Fighter.CTGY_CODE_DNRM = dbo.Category_Belt.CODE LEFT OUTER JOIN
             dbo.D$DEGR AS D$DEGR_1 ON dbo.Fighter_Public.GUDG_DEG = D$DEGR_1.VALU LEFT OUTER JOIN
             dbo.D$DEGR ON dbo.Fighter_Public.COCH_DEG = dbo.D$DEGR.VALU LEFT OUTER JOIN
             dbo.D$ACTG ON ISNULL(dbo.Fighter_Public.ACTV_TAG, '101') = dbo.D$ACTG.VALU LEFT OUTER JOIN
             dbo.D$BLOD ON dbo.Fighter_Public.BLOD_GROP = dbo.D$BLOD.VALU LEFT OUTER JOIN
             dbo.Request_Type ON (SELECT RQTP_CODE FROM Request WHERE RQID = dbo.Fighter.RQST_RQID) = dbo.Request_Type.CODE LEFT OUTER JOIN
             dbo.Region ON (dbo.Fighter.REGN_CODE = dbo.Region.CODE AND dbo.Fighter.REGN_PRVN_CODE = dbo.Region.PRVN_CODE AND dbo.Fighter.REGN_PRVN_CNTY_CODE = dbo.Region.PRVN_CNTY_CODE) LEFT OUTER JOIN
             dbo.Province ON (dbo.Fighter.REGN_PRVN_CODE = dbo.Province.CODE AND dbo.Fighter.REGN_PRVN_CNTY_CODE = dbo.Province.CNTY_CODE) INNER JOIN
             dbo.V#URFGA ON (dbo.V#URFGA.SYS_USER = UPPER(SUSER_NAME()) AND dbo.Fighter.REGN_CODE = dbo.V#URFGA.REGN_CODE AND dbo.Fighter.REGN_PRVN_CODE = dbo.V#URFGA.REGN_PRVN_CODE) LEFT OUTER JOIN

             dbo.Organ ON (dbo.Fighter_Public.SUNT_BUNT_DEPT_ORGN_CODE = dbo.Organ.CODE) LEFT OUTER JOIN
             dbo.Department ON (dbo.Fighter_Public.SUNT_BUNT_DEPT_CODE = dbo.Department.CODE AND dbo.Department.ORGN_CODE = dbo.Organ.CODE ) LEFT OUTER JOIN
             dbo.Base_Unit ON (dbo.Fighter_Public.SUNT_BUNT_CODE = dbo.Base_Unit.CODE AND dbo.Base_Unit.DEPT_ORGN_CODE = dbo.Organ.CODE AND dbo.Base_Unit.DEPT_CODE = dbo.Department.CODE) LEFT OUTER JOIN
             dbo.Sub_Unit ON (dbo.Fighter_Public.SUNT_CODE = dbo.Sub_Unit.CODE AND dbo.Sub_Unit.BUNT_DEPT_ORGN_CODE = dbo.Organ.CODE AND dbo.Sub_Unit.BUNT_DEPT_CODE = dbo.Department.CODE AND dbo.Sub_Unit.BUNT_CODE = dbo.Base_Unit.CODE)
             
WHERE     (dbo.Fighter_Public.RECT_CODE = '004') AND (dbo.Fighter.CONF_STAT = '002')
  /*AND     (dbo.Fighter.CLUB_CODE_DNRM IN (SELECT DISTINCT dbo.V#UCFGA.CLUB_CODE FROM dbo.V#UCFGA)
           OR dbo.Fighter.CLUB_CODE_DNRM IS NULL OR EXISTS(SELECT * FROM dbo.Club_Method, dbo.V#UCFGA WHERE dbo.Club_Method.COCH_FILE_NO = dbo.Fighter.FILE_NO AND dbo.Club_Method.CLUB_CODE = dbo.V#UCFGA.CLUB_CODE))*/
  AND     (@FileNo IS NULL OR dbo.Fighter.FILE_NO = @FileNo)
  AND     (dbo.Fighter.FGPB_TYPE_DNRM IN ( '002','003', '004' ) OR dbo.PLC_CLUB_U('<Club code="' + CAST(dbo.Fighter.CLUB_CODE_DNRM AS VARCHAR(20)) + '"/>') = '002')
  AND     (dbo.Fighter.ACTV_TAG_DNRM >= '101')
)
GO
