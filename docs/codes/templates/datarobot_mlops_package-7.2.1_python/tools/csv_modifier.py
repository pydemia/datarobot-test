import argparse
import numpy as np
import pandas as pd
from abc import ABC, abstractmethod


class CSVModifier(ABC):

    def __init__(self, df, column_name):
        if column_name not in df.columns:
            raise Exception(
                "Column '{}' is not present in CSV. Allowed columns: {}".format(
                    column_name, df.columns
                )
            )

        self.df = df
        self.column_name = column_name

    @abstractmethod
    def change(self):
        raise NotImplementedError("Please implement the change in modifier")

    def save(self, filename):
        self.df.to_csv(filename, encoding="utf-8", index=False)


class CSVModifierAddSubtractValue(CSVModifier):

    def __init__(self, df, column_name, change_value):
        super(CSVModifierAddSubtractValue, self).__init__(df, column_name)

        # Only float / int columns allowed to be changed here
        data_type = self.df[column_name].dtype
        if data_type not in [float, int]:
            raise Exception("Invalid column for change by value")
        self.change_value = change_value

    def change(self):
        self.df[self.column_name] += change_value


class CSVModifierAddSubtractPercentValue(CSVModifier):

    def __init__(self, df, column_name, percent_change_value):
        super(CSVModifierAddSubtractPercentValue, self).__init__(df, column_name)

        # Only float / int columns allowed to be changed here
        data_type = self.df[column_name].dtype
        if data_type not in [float, int]:
            raise Exception("Invalid column for change by value")
        self.percent_change_value = percent_change_value

    def change(self):
        self.df[self.column_name] += ((self.df[self.column_name] * self.percent_change_value) / 100)


class CSVModifierChangeRandomPercent(CSVModifier):

    def __init__(self, df, column_name, max_percent_change_value):
        super(CSVModifierChangeRandomPercent, self).__init__(df, column_name)

        # Only float / int columns allowed to be changed here
        data_type = self.df[column_name].dtype
        if data_type not in [float, int]:
            raise Exception("Invalid column for change by value")
        self.max_percent_change_value = max_percent_change_value

    def change(self):

        random_arr = np.random.randint(-1 * self.max_percent_change_value,
                                       self.max_percent_change_value,
                                       self.df.shape[0])

        df_random = pd.DataFrame(data=random_arr, columns=["random"])
        self.df[self.column_name] += self.df[self.column_name] * df_random["random"] / 100


class CSVRowDealer(CSVModifier):
    def __init__(self, df, number_of_lines, random=False):
        super(CSVRowDealer, self).__init__(df, df.columns[0])
        self.number_of_lines = number_of_lines
        self.random = random

    def change(self):
        self.df = df.sample(n=self.number_of_lines, replace=True).reset_index(drop=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--csv-filename", dest="csv_filename", required=True,
                        help="Name of CSV file to modify")
    parser.add_argument("-c", "--column-name", dest="column_name", required=True,
                        help="Name of the column in CSV to modify")
    parser.add_argument("--change-column-value", dest="change_value", required=False,
                        help="Each value in the column is changed by this amount.  For decrementing"
                             "the value, use negative number.  This will have effect of existing"
                             "distribution of values to shift to left or right")
    parser.add_argument("--change-column-value-by-percent", dest="change_value_percent",
                        required=False, help="Each value in the column is changed by this "
                                             "percentageamount.  For decrementing the "
                                             "value, use negative number.")
    parser.add_argument("--random-percent",
                        dest="change_value_random_percent",
                        required=False,
                        help="Each value in the column is changed by a random percent in the range "
                             "of +- the given value")
    parser.add_argument("--resize",
                        dest="resize",
                        required=False,
                        help="Resize the input file to the give size. The new size can be bigger"
                        " or smaller then the original size. The samples of the original file"
                        " are shuffled randomly")

    parser.add_argument("-o", "--output-csv-filename", dest="output_csv_filename", required=True,
                        help="Target CSV File to store after modification")

    args = parser.parse_args()

    df = pd.read_csv(args.csv_filename)

    if args.change_value:
        change_value = int(args.change_value)
        modifier = CSVModifierAddSubtractValue(df, args.column_name, change_value)
    elif args.change_value_percent:
        percent_change_value = int(args.change_value_percent)
        modifier = CSVModifierAddSubtractPercentValue(df, args.column_name, percent_change_value)
    elif args.change_value_random_percent:
        percent_change_value = int(args.change_value_random_percent)
        modifier = CSVModifierChangeRandomPercent(df, args.column_name, percent_change_value)
    elif args.resize:
        new_number_of_lines = int(args.resize)
        modifier = CSVRowDealer(df=df, number_of_lines=new_number_of_lines)
    else:
        raise Exception("Invalid modifier specified")

    modifier.change()
    modifier.save(args.output_csv_filename)
