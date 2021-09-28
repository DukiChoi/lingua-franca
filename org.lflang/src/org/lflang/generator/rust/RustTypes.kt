/*
 * Copyright (c) 2021, TU Dresden.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package org.lflang.generator.rust

import org.lflang.generator.TargetCode
import org.lflang.generator.TargetTypes
import org.lflang.lf.TimeUnit

object RustTypes : TargetTypes {

    override fun supportsGenerics(): Boolean = true

    override fun getTargetTimeType(): String = "Duration"

    override fun getTargetTagType(): String = "LogicalInstant"

    override fun getTargetUndefinedType(): String = "()"

    override fun getTargetFixedSizeListType(baseType: String, size: Int): String =
        "[ $baseType ; $size ]"

    override fun getTargetVariableSizeListType(baseType: String): String =
        "Vec<$baseType>"

    override fun escapeIdentifier(ident: String): String =
        if (ident in RustKeywords) "r#$ident"
        else ident

    override fun getTargetTimeExpression(magnitude: Long, unit: TimeUnit): TargetCode = when (unit) {
        TimeUnit.NSEC,
        TimeUnit.NSECS                    -> "Duration::from_nanos($magnitude)"
        TimeUnit.USEC,
        TimeUnit.USECS                    -> "Duration::from_micros($magnitude)"
        TimeUnit.MSEC,
        TimeUnit.MSECS                    -> "Duration::from_millis($magnitude)"
        TimeUnit.MIN,
        TimeUnit.MINS,
        TimeUnit.MINUTE,
        TimeUnit.MINUTES                  -> "Duration::from_secs(${magnitude * 60})"
        TimeUnit.HOUR, TimeUnit.HOURS     -> "Duration::from_secs(${magnitude * 3600})"
        TimeUnit.DAY, TimeUnit.DAYS       -> "Duration::from_secs(${magnitude * 3600 * 24})"
        TimeUnit.WEEK, TimeUnit.WEEKS     -> "Duration::from_secs(${magnitude * 3600 * 24 * 7})"
        TimeUnit.NONE, // default is the second
        TimeUnit.SEC, TimeUnit.SECS,
        TimeUnit.SECOND, TimeUnit.SECONDS -> "Duration::from_secs($magnitude)"
    }

    override fun getFixedSizeListInitExpression(contents: List<String>, withBraces: Boolean): String =
        contents.joinToString(", ", "[", "]")

    override fun getVariableSizeListInitExpression(contents: List<String>, withBraces: Boolean): String =
        contents.joinToString(", ", "vec![", "]")

    override fun getMissingExpr(): String =
        "Default::default()"
}

val RustKeywords = setOf(
    // https://doc.rust-lang.org/reference/keywords.html
    "as", "break", "const", "continue", "crate", "else",
    "enum", "extern", /*"false",*/ "fn", "for", "if", "impl",
    "in", "let", "loop", "match", "mod", "move", "mut",
    "pub", "ref", "return", /*"self",*/ "Self", "static",
    "struct", "super", "trait", /*"true",*/ "type", "unsafe",
    "use", "where", "while",
    // reserved kws
    "abstract", "async", "await", "dyn", "become", "box",
    "do", "final", "macro", "override", "priv", "typeof",
    "unsized", "virtual", "yield", "try",
    // "weak" keywords, disallow them anyway
    "union", "dyn"
)
