SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_GEXP_P]
    @Code BIGINT,
	@Gexp_Code BIGINT,
	@Grop_Type VARCHAR(3),
	@Ordr SMALLINT,
    @Grop_Desc NVARCHAR(250),
	@Stat VARCHAR(3)
AS
BEGIN
    UPDATE dbo.Group_Expense
       SET GEXP_CODE = @Gexp_Code,
           GROP_TYPE = @Grop_Type,
           ORDR = @Ordr,
           GROP_DESC = @Grop_Desc,
           STAT = @Stat
     WHERE CODE = @Code;
END
GO
