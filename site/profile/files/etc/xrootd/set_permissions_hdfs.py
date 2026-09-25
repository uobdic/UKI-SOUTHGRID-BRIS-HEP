import json
import sys

def main(json_file):
    with open(json_file) as f:
        paths_and_groups = json.load(f)
    
    for path, group in paths_and_groups.items():
        # remove all permissions for others
        print("hdfs dfs -chmod -R o-rwx {}".format(path))
        # change group to the one specified
        print("hdfs dfs -setfacl -m default:group:{}:rwx {}".format(group, path))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: set_permissions.py <path to JSON file>")
        sys.exit(1)
    
    main(sys.argv[1])
    
