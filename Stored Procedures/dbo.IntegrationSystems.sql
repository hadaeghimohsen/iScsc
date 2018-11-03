SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[IntegrationSystems]	
AS
BEGIN
	INSERT INTO dbo.Computer_Action( CODE ,COMP_NAME ,CHCK_DOBL_ATTN_STAT ,CHCK_ATTN_ALRM )
	SELECT 0, c.COMP_NAME_DNRM, '001', '001'
	  FROM dbo.V#Computers c
	 WHERE NOT EXISTS(
	       SELECT *
	         FROM dbo.Computer_Action ca
	        WHERE c.COMP_NAME_DNRM = ca.COMP_NAME
	 );

	INSERT INTO dbo.User_Region_Fgac( FGA_CODE ,REGN_PRVN_CNTY_CODE ,REGN_PRVN_CODE ,REGN_CODE ,SYS_USER ,REC_STAT ,VALD_TYPE )
   SELECT dbo.GNRT_NVID_U(), '001', '017', '001', USER_DB, '002', '002' 
     FROM dbo.V#Users 
    WHERE NOT EXISTS(
          SELECT *
            FROM dbo.User_Region_Fgac
           WHERE USER_DB = SYS_USER
    );
	
   INSERT INTO dbo.User_Club_Fgac ( FGA_CODE ,CLUB_CODE ,SYS_USER ,REC_STAT ,VALD_TYPE )
   SELECT dbo.GNRT_NVID_U(), c.CODE, USER_DB, '002', '002' 
     FROM dbo.V#Users u, dbo.Club c
    WHERE NOT EXISTS(
          SELECT *
            FROM dbo.User_Club_Fgac ucf
           WHERE u.USER_DB = ucf.SYS_USER
             AND ucf.CLUB_CODE = c.CODE
          )
      AND NOT EXISTS(
          SELECT * 
            FROM dbo.User_Club_Fgac ucf
           WHERE u.USER_DB = ucf.SYS_USER
          );
END
GO
