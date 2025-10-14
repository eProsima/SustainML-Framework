// Copyright 2025 Proyectos y Sistemas de Mantenimiento SL (eProsima).
//
// This file is part of eProsima Fast DDS Monitor.
//
// eProsima Fast DDS Monitor is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// eProsima Fast DDS Monitor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with eProsima Fast DDS Monitor. If not, see <https://www.gnu.org/licenses/>.

#include <QStringList>

#include <sustainml/tree/TreeItem.h>
#include <sustainml/tree/TreeModel.h>

#include <iostream> // debug

TreeModel::TreeModel(
        const json& data,
        QObject* parent)
    : QAbstractItemModel(parent)
{
    root_item_ = new TreeItem(QList<QString>() << "Name" << "Value");
    setup_model_data(data, root_item_);
}

TreeModel::TreeModel(
        QObject* parent)
    : QAbstractItemModel(parent)
{
    root_item_ = new TreeItem(QList<QString>() << "Name" << "Value");
}

TreeModel::~TreeModel()
{
    beginResetModel();
    root_item_->clear();
    endResetModel();
    delete root_item_;
}

int TreeModel::columnCount(
        const QModelIndex& parent) const
{
    if (parent.isValid())
    {
        return get_item(parent)->column_count();
    }
    else
    {
        return root_item_->column_count();
    }
}

QVariant TreeModel::data(
        const QModelIndex& index,
        int role) const
{
    if (!index.isValid())
    {
        std::cout << "TreeModel::data - invalid index" << std::endl;
        return QVariant();
    }

    TreeItem* item = get_item(index);
    if (!item)
    {
        std::cout << "TreeModel::data - null item" << std::endl;
        return QVariant();
    }

    QVariant result;
    switch (role)
    {
        case treeModelNameRole:
            result = item->get_item_name();
            std::cout << "TreeModel::data - name role: '" << result.toString().toStdString() << "'" << std::endl;
            break;
        case treeModelValueRole:
            result = item->get_item_value();
            std::cout << "TreeModel::data - value role: '" << result.toString().toStdString() << "'" << std::endl;
            break;
        default:
            std::cout << "TreeModel::data - unknown role: " << role << std::endl;
            break;
    }

    return result;
}

Qt::ItemFlags TreeModel::flags(
        const QModelIndex& index) const
{
    if (!index.isValid())
    {
        return Qt::NoItemFlags;
    }

    return QAbstractItemModel::flags(index);
}

QModelIndex TreeModel::index(
        int row,
        int column,
        const QModelIndex& parent) const
{
    if (!hasIndex(row, column, parent))
    {
        return QModelIndex();
    }

    TreeItem* parent_item;
    if (!parent.isValid())
    {
        parent_item = root_item_;
    }
    else
    {
        parent_item = static_cast<TreeItem*>(parent.internalPointer());
    }

    TreeItem* child_item = parent_item->child_item(row);
    if (child_item)
    {
        return createIndex(row, column, child_item);
    }
    else
    {
        return QModelIndex();
    }
}

QModelIndex TreeModel::parent(
        const QModelIndex& index) const
{

    TreeItem* parent_item = nullptr;
    TreeItem* child_item = nullptr;

    if (!index.isValid())
    {
        return QModelIndex();
    }

    if ((child_item = get_item(index)) != nullptr)
    {
        if ((parent_item = child_item->parent_item()) != nullptr)
        {
            if (parent_item == root_item_)
            {
                return QModelIndex();
            }

            return createIndex(parent_item->row(), 0, parent_item);
        }
    }

    return QModelIndex();
}

int TreeModel::rowCount(
        const QModelIndex& parent) const
{
    TreeItem* parent_item;
    if (parent.column() > 0)
    {
        return 0;
    }

    if (!parent.isValid())
    {
        parent_item = root_item_;
    }
    else
    {
        parent_item = get_item(parent);
    }

    return parent_item->child_count();
}

QHash<int, QByteArray> TreeModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[treeModelNameRole] = "name";
    roles[treeModelValueRole] = "value";

    return roles;
}

TreeItem* TreeModel::get_item(
        const QModelIndex& index) const
{

    TreeItem* item = nullptr;

    if (index.isValid())
    {
        item = static_cast<TreeItem*>(index.internalPointer());
        if (item != nullptr)
        {
            return item;
        }
    }

    return root_item_;
}

void TreeModel::updateFromJsonString(const QString& json_str)
{
    try
    {
        json parsed = json::parse(json_str.toStdString());
        std::cout << "TreeModel::updateFromJsonString: parsing succeeded." << std::endl;    // debug
        if (parsed.is_object() || parsed.is_array())
        {
            std::cout << "TreeModel::updateFromJsonString: container type = "
                      << (parsed.is_object() ? "object" : "array")
                      << ", size = " << parsed.size() << std::endl;
        }
        else
        {
            std::cout << "TreeModel::updateFromJsonString: primitive JSON value" << std::endl;
        }
        std::cout << "TreeModel::updateFromJsonString: content:\n" << parsed.dump(2) << std::endl;  // debug
        update(parsed);
    }
    catch (const std::exception& e)
    {
        std::cout << "TreeModel::updateFromJsonString: failed to parse JSON: " << e.what() << std::endl;
    }
}

void TreeModel::setup_model_data(
        const json& json_data,
        TreeItem* parent,
        bool _first /* = true */)
{
    QList<QString> data;
    bool last_child = false;

    if (json_data.is_object())
    {
        // Handle JSON objects
        for (json::const_iterator it = json_data.begin(); it != json_data.end(); ++it)
        {
            data << QString::fromUtf8(it.key().c_str());

            if (it.value().is_primitive())
            {
                if (it.value().is_string())
                {
                    data << QString::fromUtf8(static_cast<std::string>(it.value()).c_str());
                }
                else if (it.value().is_number())
                {
                    data << QString::number(static_cast<double>(it.value()));
                }
                else if (it.value().is_boolean())
                {
                    data << (it.value() ? QString("true") : QString("false"));
                }
                else if (it.value().is_null())
                {
                    data << "null";
                }
                else
                {
                    data << "-";
                }
                last_child = true;
            }
            else
            {
                data << ""; // empty value for containers
            }

            TreeItem* current_child = new TreeItem(data, parent);
            if (!last_child)
            {
                setup_model_data(it.value(), current_child, false);
            }

            parent->append_child(current_child);
            data.clear();
            last_child = false;
        }
    }
    else if (json_data.is_array())
    {
        // Handle JSON arrays
        for (size_t i = 0; i < json_data.size(); ++i)
        {
            data << QString("[%1]").arg(i); // array index as key

            const auto& item = json_data[i];
            if (item.is_primitive())
            {
                if (item.is_string())
                {
                    data << QString::fromUtf8(static_cast<std::string>(item).c_str());
                }
                else if (item.is_number())
                {
                    data << QString::number(static_cast<double>(item));
                }
                else if (item.is_boolean())
                {
                    data << (item ? QString("true") : QString("false"));
                }
                else if (item.is_null())
                {
                    data << "null";
                }
                else
                {
                    data << "-";
                }
                last_child = true;
            }
            else
            {
                data << ""; // empty value for containers
            }

            TreeItem* current_child = new TreeItem(data, parent);
            if (!last_child)
            {
                setup_model_data(item, current_child, false);
            }

            parent->append_child(current_child);
            data.clear();
            last_child = false;
        }
    }
    else if (json_data.is_primitive())
    {
        // Handle primitive JSON (single values)
        data << "value";
        if (json_data.is_string())
        {
            data << QString::fromUtf8(static_cast<std::string>(json_data).c_str());
        }
        else if (json_data.is_number())
        {
            data << QString::number(static_cast<double>(json_data));
        }
        else if (json_data.is_boolean())
        {
            data << (json_data ? QString("true") : QString("false"));
        }
        else if (json_data.is_null())
        {
            data << "null";
        }
        else
        {
            data << "-";
        }

        TreeItem* current_child = new TreeItem(data, parent);
        parent->append_child(current_child);
        data.clear();
    }

    // Add empty child to prevent TreeView collapse issues
    if (_first)
    {
        TreeItem* empty_child = new TreeItem(data, parent);
        parent->append_child(empty_child);
    }
}

void TreeModel::clear()
{
    root_item_->clear();
}

void TreeModel::update(
        json data)
{
    std::unique_lock<std::mutex> lock(update_mutex_);

    beginResetModel();
    clear();
    setup_model_data(data, root_item_);
    endResetModel();
    emit updatedData();
}
