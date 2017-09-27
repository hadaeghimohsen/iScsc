SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#CellPhonCollection] as
SELECT CASE WHEN LEN(f.CELL_PHON_DNRM) = 0 THEN N'ثبت نشده' 
            ELSE N'ثبت شده'
       END AS X,
       COUNT(*) Y
  FROM dbo.Fighter f
WHERE f.CONF_STAT = '002'
GROUP BY 
       CASE WHEN LEN(f.CELL_PHON_DNRM) = 0 THEN N'ثبت نشده' 
            ELSE N'ثبت شده'
       END;

GO
