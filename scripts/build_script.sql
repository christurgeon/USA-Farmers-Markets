-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema farmers_markets
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema farmers_markets
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `farmers_markets` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `farmers_markets` ;

-- -----------------------------------------------------
-- Table `farmers_markets`.`markets`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `farmers_markets`.`markets` (
  `markets_id` INT(11) NOT NULL,
  `market_name` VARCHAR(100) NOT NULL,
  `website` VARCHAR(175) NULL DEFAULT NULL,
  `state` VARCHAR(20) NOT NULL,
  `city` VARCHAR(100) NULL DEFAULT NULL,
  `zipcode` INT(11) NOT NULL,
  `latitude` DOUBLE NULL DEFAULT NULL,
  `longitude` DOUBLE NULL DEFAULT NULL,
  PRIMARY KEY (`markets_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
