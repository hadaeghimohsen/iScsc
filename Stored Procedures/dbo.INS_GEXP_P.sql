SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_GEXP_P]
	@Gexp_Code BIGINT,
	@Grop_Type VARCHAR(3),
	@Ordr SMALLINT,
   @Grop_Desc NVARCHAR(250),
	@Stat VARCHAR(3),
	@Link_Join VARCHAR(100),
	@Grop_Ordr INT
AS
BEGIN
    INSERT INTO dbo.Group_Expense (GEXP_CODE,CODE,GROP_TYPE,ORDR,GROP_DESC,STAT, LINK_JOIN, GROP_ORDR)
    SELECT @Gexp_Code, 0, @Grop_Type, @Ordr, @Grop_Desc, @Stat, @Link_Join, @Grop_Ordr
     WHERE NOT EXISTS (
           SELECT * 
             FROM dbo.Group_Expense ge
            WHERE ge.GEXP_CODE = @Gexp_Code
              AND ge.GROP_TYPE = @Grop_Type
              AND ge.GROP_DESC = @Grop_Desc
              AND ge.LINK_JOIN = @Link_Join
           );	
END
GO
