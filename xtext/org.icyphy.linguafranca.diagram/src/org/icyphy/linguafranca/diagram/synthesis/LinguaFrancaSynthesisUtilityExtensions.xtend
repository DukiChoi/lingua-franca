package org.icyphy.linguafranca.diagram.synthesis

import de.cau.cs.kieler.klighd.kgraph.KGraphElement
import de.cau.cs.kieler.klighd.kgraph.KGraphFactory
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import java.util.Map
import java.util.function.Supplier
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.TerminalRule
import org.eclipse.xtext.nodemodel.impl.CompositeNode
import org.eclipse.xtext.nodemodel.impl.HiddenLeafNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.resource.XtextResource
import org.icyphy.ASTUtils
import org.icyphy.linguaFranca.Reactor
import org.icyphy.linguaFranca.Value

@ViewSynthesisShared
class LinguaFrancaSynthesisUtilityExtensions extends AbstractSynthesisExtensions {
	
	extension KGraphFactory = KGraphFactory.eINSTANCE
	
	/**
	 * Converts a timing value into readable text
	 */
	def String toText(Value value) {
		if (value !== null) {
			if (value.parameter !== null) {
                return value.parameter.name
            } else if (value.time !== null) {
                return value.time.interval +
                        value.time.unit.toString
            } else if (value.literal !== null) {
                return value.literal
            } else if (value.code !== null) {
                ASTUtils.toText(value.code)
            }
		}
		return ""
	}
	
	/**
	 * Returns true if the reactor as has inner reactions or instances
	 */
	def hasContent(Reactor reactor) {
		return !reactor.reactions.empty || !reactor.instantiations.empty
	}
	
	/**
	 * Trims the hostcode of reactions.
	 */
	def trimCode(String code) {
		if (code.nullOrEmpty) {
			return code
		}
		try {
			val lines = newArrayList(code.split("\n"))
			var contentStart = 0
			
			// Remove start pattern
			if (!lines.empty) {
				if (lines.head.trim().equals("{=")) {
					lines.remove(0) // skip
				} else {
					lines.set(0, lines.head.replace("{=", "").trim())
					contentStart = 1
				}
			}
			
			// Remove end pattern
			if (!lines.empty) {
				if (lines.last.trim.equals("=}")) {
					lines.remove(lines.size - 1) // skip
				} else {
					lines.set(lines.size - 1, lines.last.replace("=}", ""))
				}
			}
			
			// Find indentation
			var String indentation = null
			while (indentation === null && lines.size > contentStart) {
				val firstLine = lines.get(contentStart)
				val trimmed = firstLine.trim()
				if (trimmed.empty) {
					lines.set(contentStart, "")
					contentStart++
				} else {
					val firstCharIdx = firstLine.indexOf(trimmed.charAt(0))
					indentation = firstLine.substring(0, firstCharIdx)
				}
			}
			
			// Remove root indentation
			if (!lines.empty) {
				for (i : 0..lines.size-1) {
					if (lines.get(i).startsWith(indentation)) {
						lines.set(i, lines.get(i).substring(indentation.length))
					}
				}
			}
			
			return lines.join("\n")
		} catch(Exception e) {
			e.printStackTrace
			return code
		}
	}
	
	/**
	 * Sets KGE ID.
	 */
	def setID(KGraphElement kge, String id) {
		kge.data.add(createKIdentifier => [it.setId(id)])
	}
	
	/**
	 * Utility to get the value in a map or put an initial value and get that one.
	 */
	def <K,V> V getOrInit(Map<K, V> map, K key, Supplier<V> init) {
		if (map === null) {
			return null
		} else if (map.containsKey(key)) {
			return map.get(key)
		} else {
			val value = init.get()
			map.put(key, value)
			return value
		}
	}
	
	/**
	 * Retrieves comments associated with model element form the AST.
	 */
	def String findComments(EObject object) {
		if (object.eResource instanceof XtextResource) {
			val compNode = NodeModelUtils.findActualNodeFor(object)
			if (compNode !== null) {
				val comments = newArrayList
				var node = compNode.firstChild
				while (node instanceof CompositeNode) {
					node = node.firstChild
				}
				while (node instanceof HiddenLeafNode) { // only comments preceding start of element
					val rule = node.grammarElement
					if (rule instanceof TerminalRule) {
						if ("SL_COMMENT".equals(rule.name)) {
							comments += node.text.substring(2).trim()
						} else if ("ML_COMMENT".equals(rule.name)) {
							var block = node.text
							block = block.substring(2, block.length - 2).trim()
							val lines = block.split("\n").map[trim()].toList
							comments += lines.map[
								if (it.startsWith("* ")) {
									it.substring(2)
								} else if (it.startsWith("*")) {
									it.substring(2)
								} else {
									it
								}
							].join("\n")
						}
					}
					node = node.nextSibling
				}
				if (!comments.empty) {
					return comments.join("\n")
				}
			}
		}
		return null
	}

}
