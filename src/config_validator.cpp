//----------------------------------------------------------------------------
/// \file  config_validator.cpp
//----------------------------------------------------------------------------
/// \brief Implementation of configuration validation class.
//----------------------------------------------------------------------------
// Copyright (c) 2011 Serge Aleynikov <saleyn@gmail.com>
// Created: 2011-09-10
//----------------------------------------------------------------------------
/*
***** BEGIN LICENSE BLOCK *****

This file is part of the utxx open-source project.

Copyright (C) 2011 Serge Aleynikov <saleyn@gmail.com>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

***** END LICENSE BLOCK *****
*/

#include <utxx/config_tree.hpp>
#include <utxx/config_validator.hpp>
#include <boost/algorithm/string/replace.hpp>

namespace utxx {
namespace config {

const char* type_to_string(option_type_t a_type) {
    switch (a_type) {
        case STRING:    return "string";
        case INT:       return "int";
        case BOOL:      return "bool";
        case FLOAT:     return "float";
        case ANONYMOUS: return "anonymous";
        case BRANCH:    return "branch";
        default:        return "undefined";
    }
}

std::string option::to_string() const {
    std::stringstream s;
    s   << "option{name=" << name
        << ",type=" << type_to_string(opt_type);
    if (!description.empty())
        s << ",desc=\"" << description << '"';
    if (name_choices.size()) {
        s << ",names=["; bool l_first = true;
        BOOST_FOREACH(const std::string& v, name_choices) {
            if (!l_first) s << ";";
            l_first = false;
            s << '"' << v << '"';
        }
        s << ']';
    }
    if (value_choices.size()) {
        s << ",values=["; bool l_first = true;
        BOOST_FOREACH(const variant& v, value_choices) {
            if (!l_first) s << ";";
            l_first = false;
            s << value(v);
        }
        s << "]";
    }
    if (!default_value.is_null())
        s << ",default=" << value(default_value);
    if (!min_value.is_null())
        s << (value_type == STRING ? ",min_length=" : ",min=") << value(min_value);
    if (!max_value.is_null())
        s << (value_type == STRING ? ",max_length=" : ",max=") << value(max_value);
    s << ",required="   << (required ? "true" : "false");
    s << ",unique="     << (unique ? "true" : "false");
    if (children.size()) {
        bool l_first = true;
        s << ",children=[";
        BOOST_FOREACH(const option_map::value_type& o, children) {
            if (!l_first) s << ",";
            l_first = false;
            s << "\n  " << o.second.to_string();
        }
        s << "\n]";
    }
    s << "}";
    return s.str();
}

namespace {
    std::string value(const variant& v) {
        return (v.type() == variant::TYPE_STRING)
            ? std::string("\"") + v.to_string() + "\""
            : v.to_string();
    }
}

config_path validator::strip_root(const config_path& a_root_path) const
    throw(config_error)
{
    /// Example: m_root      = a.b.c
    ///          a_root_path = a.b.c.d.e
    ///          Return     -> d.e

    char sep = a_root_path.separator();
    std::string s(a_root_path.dump());
    std::string r(m_root.dump());

    if (s.size() < r.size())
        throw config_error(a_root_path, "Path is shorter than root!");
    if (s.substr(0, r.size()) != r || (s.size() > r.size() && s[r.size()] != sep))
        throw config_error(p, "Sub-path not found in root path");

    return s.erase(s.size() > r.size() ? r.size()+1 : r.size());
}

const option* validator::find(
    config_path& a_suffix, const option_map& a_options) throw ()
{
    if (a_suffix.empty())
        return NULL;

    std::string s = a_suffix.reduce();
    size_t n = s.find_first_of('[');
    if (n != std::string::npos)
        s.erase(n);

    option_map::const_iterator it = a_options.find(s);
    if (it == a_options.end())
        return NULL;
    else if (a_suffix.empty())
        return &it->second;

    return find(a_suffix, it->second.children);
}

const option* validator::find(const config_path& a_path,
    const config_path& a_root_path) const throw ()
{
    try {
        config_path p = a_root_path.empty()
            ? strip_root(a_path)
            : (strip_root(a_root_path) / a_path.dump());
        return find(p, m_options);
    } catch (config_error&) {
        return NULL;
    }
}

template <class T>
T validator::get(const config_path& a_option, const config_tree& a_config)
    const throw(config_error)
{
    T l_value;
    const option* l_opt = find(a_option, a_config.root_path());
    boost::optional<T> v = a_config.get_optional<T>(a_option);
    if (v) return *v;
    if (!l_opt)
        throw config_error(
            a_config.root_path().empty() ? a_option : a_config.root_path() / a_option,
            "Required option doesn't have default value!");
    return l_opt->default_value.get<T>();
}

const variant_tree_base& validator::get_child(const config_path& a_option,
    const config_tree& a_config) const throw(config_error)
{
    const static config_tree s_null;
    boost::optional<const variant_tree_base&> t = a_config.get_child_optional(a_option);
    if (!t) {
        default_value(a_option, a_config.root_path()); // No default -> exception thrown
        return s_null; // Return empty tree in case there's a node in the metadata.
    }
    return *t;
}

const variant& validator::default_value(const config_path& a_path,
    const config_path& a_root_path) const throw (config_error)
{
    const option* l_def = find(a_path, a_root_path);

    if (!l_def)
        throw config_error(
            a_root_path.empty() ? a_path : a_root_path / a_path,
            "Required option doesn't have default value!");

    return l_def->default_value;
}

config_path validator::format_name(const config_path& a_root,
    const option& a_opt, const std::string& a_cfg_opt,
    const std::string& a_cfg_value) const
{
    config_path s = a_root / a_opt.name;
    if (!a_cfg_opt.empty() && a_cfg_opt != a_opt.name) // && a_opt.opt_type == ANONYMOUS)
        s /= a_cfg_opt;
    if (a_cfg_value != std::string()) // && !a_opt.unique)
        s = s.dump() + '[' + a_cfg_value + ']';
    return s;
}

void validator::validate(const config_path& a_root, variant_tree_base& a_config,
    const option_map& a_opts, bool a_fill_defaults) const throw (config_error)
{
    check_unique(a_root, a_config, a_opts);
    check_required(a_root, a_config, a_opts);

    BOOST_FOREACH(variant_tree::value_type& vt, a_config) {
        bool l_match = false;
        BOOST_FOREACH(const typename option_map::value_type& ovt, a_opts) {
            const option& opt = ovt.second;
            if (opt.opt_type == ANONYMOUS) {
                if (!all_anonymous(a_opts))
                    throw config_error(format_name(a_root, opt,
                        vt.first, vt.second.data().to_string()),
                        "Check XML spec. Cannot mix anonymous and named options "
                        "in one section!");
                check_option(a_root, vt, opt, a_fill_defaults);
                l_match = true;
                break;
            } else if (opt.name == vt.first) {
                check_option(a_root, vt, opt, a_fill_defaults);
                l_match = true;
                break;
            }
        }
        if (!l_match) {
            config_path p; p /= vt.first;
            throw config_error(p, "Unsupported config option!");
        }
    }
}

void validator::check_required(const config_path& a_root,
    const variant_tree_base& a_config, const option_map& a_opts) const throw (config_error)
{
    #ifdef TEST_CONFIG_VALIDATOR
    std::cout << "check_required(" << a_root << ", cfg.count=" << a_config.size()
        << ", opts.count=" << a_opts.size() << ')' << std::endl;
    #endif
    BOOST_FOREACH(const typename option_map::value_type& ovt, a_opts) {
        const option& opt = ovt.second;
        if (opt.required && opt.default_value.is_null()) {
            #ifdef TEST_CONFIG_VALIDATOR
            std::cout << "  checking_option(" << format_name(a_root, opt) << ")"
                << (opt.opt_type == ANONYMOUS ? " [anonymous]" : "")
                << (opt.unique ? " [unique]" : "")
                << " [required, no default]"
                << std::endl;
            #endif
            if (opt.opt_type == ANONYMOUS) {
                if (a_config.empty())
                    throw config_error(format_name(a_root, opt),
                        "Check XML spec. Missing required value of anonymous option!");
            } else {
                bool l_found = false;
                BOOST_FOREACH(const config_tree::value_type& vt, a_config)
                    if (vt.first == opt.name) {
                        #ifdef TEST_CONFIG_VALIDATOR
                        std::cout << "    found: "
                            << format_name(a_root, opt, vt.first, vt.second.data().to_string())
                            << ", value=" << vt.second.data().to_string()
                            << ", type=" << type_to_string(opt.opt_type)
                            << std::endl;
                        #endif

                        if (opt.opt_type == BRANCH) {
                            l_found = true;
                            break;
                        }

                        if (vt.second.data().is_null())
                            throw config_error(format_name(a_root, opt,
                                    vt.first, vt.second.data().to_string()),
                                "Missing value of the required option "
                                "and no default provided!");
                        l_found = true;
                        if (opt.unique)
                            break;
                    }

                if (!l_found && (opt.opt_type != BRANCH || opt.children.empty()))
                    throw config_error(format_name(a_root, opt),
                        "Missing required ", (opt.opt_type == BRANCH ? "branch" : "option"),
                        " with no default!");
            }
        }
        #ifdef TEST_CONFIG_VALIDATOR
        else {
            std::cout << "  option(" << format_name(a_root, opt)
                << ") is " << (opt.required ? "required" : "not required")
                << " and " << (opt.default_value.is_null()
                    ? "no default"
                    : (std::string("has default=") + opt.default_value.to_string()))
                << std::endl;
        }
        #endif

        if (opt.opt_type == ANONYMOUS) {
            #ifdef TEST_CONFIG_VALIDATOR
            if (a_config.size())
                std::cout << "  Checking children of anonymous node "
                    << format_name(a_root, opt) << std::endl;
            #endif
            BOOST_FOREACH(const config_tree::value_type& vt, a_config)
                check_required(
                    format_name(a_root, opt, vt.first, vt.second.data().to_string()),
                    vt.second, opt.children);
        } else {
            #ifdef TEST_CONFIG_VALIDATOR
            if (opt.children.size())
                std::cout << "  Checking children of " << format_name(a_root, opt) << std::endl;
            #endif
            config_path l_req_name;
            bool l_has_req = has_required_child_options(opt.children, l_req_name);
            bool l_found   = false;

            BOOST_FOREACH(const config_tree::value_type& vt, a_config)
                if (vt.first == opt.name) {
                    l_found = true;
                    if (l_has_req) {
                        if (!vt.second.size())
                            throw config_error(format_name(a_root, opt,
                                    vt.first, vt.second.data().to_string()),
                                std::string("Option is missing required child option ") +
                                    l_req_name.dump());
                        check_required(
                            format_name(a_root, opt, vt.first, vt.second.data().to_string()),
                            vt.second, opt.children);
                    }
                    if (!opt.children.size() && vt.second.size())
                        throw config_error(format_name(a_root, opt, vt.first,
                                vt.second.data().to_string()),
                            "Option is not allowed to have child nodes!");
                }

            if (!l_found && l_has_req)
                throw config_error(format_name(a_root, opt),
                    std::string("Missing a required child option ") + l_req_name.dump());
        }
    }
}


void validator::check_option(const config_path& a_root, config_tree::value_type& a_vt,
    const option& a_opt, bool a_fill_defaults) const throw(config_error)
{
    try {
        // Populate default value
        if (!a_opt.required && a_vt.second.data().is_null()) {
            if (a_opt.default_value.is_null() && a_opt.opt_type != BRANCH)
                throw std::invalid_argument("Check XML spec. Required option is missing default value!");
            BOOST_ASSERT(
                (a_opt.opt_type == BRANCH && a_opt.default_value.is_null()) ||
                (to_option_type(a_opt.default_value.type()) == a_opt.value_type));
            if (a_fill_defaults && !a_opt.default_value.is_null())
                a_vt.second.data() = a_opt.default_value;
        }

        switch (a_opt.value_type) {
            case STRING:
                if (a_vt.second.data().type() != variant::TYPE_STRING)
                    throw std::invalid_argument("Wrong type - expected string!");
                if (!a_opt.min_value.is_null() &&
                     a_vt.second.data().to_str().size() < (size_t)a_opt.min_value.to_int())
                    throw std::invalid_argument("String value too short!");
                if (!a_opt.max_value.is_null() &&
                     a_vt.second.data().to_str().size() > (size_t)a_opt.max_value.to_int())
                    throw std::invalid_argument("String value too long!");
                break;
            case INT:
                if (a_vt.second.data().type() != variant::TYPE_INT)
                    throw std::invalid_argument("Wrong type - expected integer!");
                if (!a_opt.min_value.is_null() && a_opt.min_value > a_vt.second.data())
                    throw std::invalid_argument("Value too small!");
                if (!a_opt.max_value.is_null() && a_opt.max_value < a_vt.second.data())
                    throw std::invalid_argument("Value too large!");
                break;
            case BOOL:
                if (a_vt.second.data().type() != variant::TYPE_BOOL)
                    throw std::invalid_argument("Wrong type - expected boolean true/false!");
                break;
            case FLOAT:
                if (a_vt.second.data().type() != variant::TYPE_DOUBLE)
                    throw std::invalid_argument("Wrong type - expected float!");
                if (!a_opt.min_value.is_null() && a_opt.min_value > a_vt.second.data())
                    throw std::invalid_argument("Value too small!");
                if (!a_opt.max_value.is_null() && a_opt.max_value < a_vt.second.data())
                    throw std::invalid_argument("Value too large!");
                break;
            default: {
                // Allow anonymous options to have no value (since the
                // name defines the value)
                if (a_opt.opt_type == ANONYMOUS || a_opt.opt_type == BRANCH)
                    break;
                throw config_error(format_name(a_root, a_opt, a_vt.first,
                        a_vt.second.data().to_string()),
                    "Check XML spec. Option's value_type '",
                    type_to_string(a_opt.value_type),
                    "' is invalid!");
            }
        }

        if (a_opt.required &&
                a_opt.opt_type != ANONYMOUS &&
                a_opt.opt_type != BRANCH &&
                a_vt.second.data().is_null())
            throw std::invalid_argument("Required value missing!");
        if (a_vt.first.empty())
            throw std::invalid_argument("Expected non-empty name!");

        switch (a_opt.opt_type) {
            case STRING:    break;
            case ANONYMOUS: break;
            case BRANCH:    break;
            default: {
                throw config_error(format_name(a_root, a_opt, a_vt.first,
                        a_vt.second.data().to_string()),
                    "Check XML spec. Unsupported type of option: ",
                    type_to_string(a_opt.opt_type));
            }
        }

        if (!a_opt.name_choices.empty()) {
            if (a_opt.opt_type != ANONYMOUS)
                throw config_error(format_name(a_root, a_opt, a_vt.first,
                        a_vt.second.data().to_string()),
                    "Check XML spec. Non-anonymous option cannot have name choices!");
            if (a_opt.name_choices.find(a_vt.first) == a_opt.name_choices.end())
                throw std::invalid_argument("Invalid name given to anonymous option!");
        }

        if (!a_opt.value_choices.empty())
            if (a_opt.value_choices.find(a_vt.second.data()) == a_opt.value_choices.end()) {
                throw config_error(format_name(a_root, a_opt,
                        a_vt.first, a_vt.second.data().to_string()),
                    "Value is not allowed for option!");
            }
        if (!a_opt.children.empty())
            validate(a_root / a_opt.name, a_vt.second, a_opt.children, a_fill_defaults);
    } catch (std::invalid_argument& e) {
        throw config_error(format_name(a_root, a_opt, a_vt.first,
                a_vt.second.data().to_string()),
                e.what());
    }
}

option_type_t validator::to_option_type(variant::value_type a_type) {
    switch (a_type) {
        case variant::TYPE_STRING:  return STRING;
        case variant::TYPE_INT:     return INT;
        case variant::TYPE_BOOL:    return BOOL;
        case variant::TYPE_DOUBLE:  return FLOAT;
        default:                    return UNDEF;
    }
}

std::string validator::usage(const std::string& a_indent) const {
    std::stringstream s;
    dump(s, a_indent, 0, m_options);
    return s.str();
}

std::ostream& validator::dump(std::ostream& out, const std::string& a_indent,
        int a_level, const option_map& a_opts) {
    std::string l_indent = a_indent + std::string(a_level, ' ');
    BOOST_FOREACH(const typename option_map::value_type& ovt, a_opts) {
        const option& opt = ovt.second;
        out << l_indent << opt.name
            << (opt.opt_type == ANONYMOUS ? " (anonymous): " : ": ")
            << type_to_string(opt.value_type) << std::endl;
        if (!opt.description.empty())
            out << l_indent << "  Description: "
                << boost::algorithm::replace_all_copy(
                    opt.description, l_indent + std::string(15, ' '), "-")
                << std::endl;
        if (!opt.unique)
            out << l_indent << "       Unique: true" << std::endl;
        if (!opt.required) {
            if (!opt.default_value.is_null())
                out << l_indent << "      Default: "
                    << value(opt.default_value) << std::endl;
        } else
            out << l_indent << "     Required: true" << std::endl;

        if (!opt.min_value.is_null() || !opt.max_value.is_null())
            out << l_indent << "         "
                << (!opt.min_value.is_null()
                        ? std::string(opt.value_type == STRING
                                       ? "MinLength: " : " Min: ")
                            + value(opt.min_value)
                        : std::string())
                << (!opt.max_value.is_null()
                        ? std::string(opt.value_type == STRING
                                       ? "MaxLength: " : " Max: ")
                            + value(opt.max_value)
                        : std::string());
        out << std::endl;
        if (opt.children.size())
            dump(out, l_indent, a_level+2, opt.children);
    }
    return out;
}

void validator::check_unique
(
    const config_path& a_root,
    const variant_tree_base& a_config,
    const option_map& a_opts
) const throw(config_error) {
    string_set l_names;
    BOOST_ASSERT(a_opts.size() > 0);
    BOOST_FOREACH(const config_tree::value_type& vt, a_config) {
        if (l_names.find(vt.first) == l_names.end())
            l_names.insert(vt.first);
        else {
            BOOST_FOREACH(const typename option_map::value_type& ovt, a_opts) {
                const option& o = ovt.second;
                if (o.name == vt.first && o.unique)
                    throw config_error(format_name(a_root, o, vt.first,
                          vt.second.data().to_string()),
                          "Non-unique config option found!");
            }
        }
    }
}

bool validator::has_required_child_options(const option_map& a_opts,
    config_path& a_req_option_path) const
{
    BOOST_FOREACH(const typename option_map::value_type& ovt, a_opts) {
        const option& opt = ovt.second;
        config_path l_path = a_req_option_path / opt.name;
        if (opt.required) {
            a_req_option_path = l_path;
            return true;
        }
        if (has_required_child_options(opt.children, l_path)) {
            a_req_option_path = l_path;
            return true;
        }
    }
    return false;
}


} // namespace config
} // namespace utxx
